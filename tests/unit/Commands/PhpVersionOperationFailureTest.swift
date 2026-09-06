//
//  PhpVersionOperationFailureTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

@Suite(.serialized)
struct PhpVersionOperationFailureTest {
    @Test(arguments: [false, true])
    func failed_operation_refreshes_installed_and_active_php_before_becoming_idle(installationRemoved: Bool) async throws {
        let configuration = TestableConfigurations.working
        let container = Container.fake(
            shell: configuration.shellOutput, files: configuration.filesystem,
            commands: configuration.commandOutput
        )
        let previousContainer = App.shared.container
        App.shared.container = container
        container.preferences.cachedPreferences[.iconTypeToDisplay] = MenuBarIcon.noIcon.rawValue
        let previousValetInstalled = Valet.shared.installed
        let previousValetVersion = Valet.shared.version
        let previousAlias = PhpEnvironments.brewPhpAlias
        let previousFormulae = Brew.shared.formulae.phpVersions
        let previousVisibility = MainMenu.shared.statusItem.isVisible
        MainMenu.shared.statusItem.isVisible = false
        defer {
            App.shared.container = previousContainer
            Valet.shared.installed = previousValetInstalled
            Valet.shared.version = previousValetVersion
            PhpEnvironments.brewPhpAlias = previousAlias
            Brew.shared.formulae.phpVersions = previousFormulae
            MainMenu.shared.statusItem.isVisible = previousVisibility
        }
        Valet.shared.installed = false
        Valet.shared.version = nil
        container.phpEnvs.homebrewPackage = HomebrewPackage(
            full_name: "php", aliases: [], installed: [],
            versions: HomebrewVersion(stable: "8.4.5", head: nil, bottle: true), linked_keg: nil
        )
        await container.phpEnvs.detectPhpVersions()
        #expect(try #require(container.phpEnvs.cachedPhpInstallations["8.3"]).isHealthy)
        #expect(try #require(container.phpEnvs.currentInstall).hasErrorState == false)

        let handler = HealthRecordingFormulaeHandler()
        let view = PhpVersionManagerView(formulae: BrewFormulaeObservable(), handler: handler)
        while view.status.busy { await Task.yield() }
        let command = FailingPhpModification(container, removesInstallation: installationRemoved)
        await view.runCommand(command)

        if installationRemoved {
            #expect(container.phpEnvs.cachedPhpInstallations["8.3"] == nil)
            #expect(!container.phpEnvs.availablePhpVersions.contains("8.3"))
            #expect(container.phpEnvs.currentInstall == nil)
        } else {
            #expect(try #require(container.phpEnvs.cachedPhpInstallations["8.3"]).isHealthy == false)
            #expect(try #require(container.phpEnvs.currentInstall).hasErrorState)
        }
        #expect(handler.lastRefreshWasBusy)
        #expect(handler.lastRefreshHadHealthyInstallation == false)
        #expect(!container.phpEnvs.isBusy)
        #expect(!view.status.busy)
        // Drain menu updates before restoring the shared container.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

private final class FailingPhpModification: ModifyPhpVersionCommand {
    let removesInstallation: Bool

    init(_ container: Container, removesInstallation: Bool) {
        self.removesInstallation = removesInstallation
        super.init(container, title: "Test failure", upgrading: [], installing: [])
    }

    nonisolated override func execute(
        shell: ShellProtocol, onProgress: @escaping @Sendable (BrewCommandProgress) -> Void
    ) async throws {
        if removesInstallation {
            try container.filesystem.remove("/opt/homebrew/opt/php@8.3/bin/php")
            try container.filesystem.remove("/opt/homebrew/bin/php-config")
        } else {
            let command = container.command as! TestableCommand
            command.updateOutputs([
                "/opt/homebrew/opt/php@8.3/bin/php-config --version": "not a version",
                "/opt/homebrew/bin/php-config --version": "not a version"
            ])
        }
        throw BrewCommandError(error: "Simulated failed installation", log: ["Installation interrupted"])
    }
}

private final class HealthRecordingFormulaeHandler: FakeBrewFormulaeHandler {
    var lastRefreshWasBusy = false
    var lastRefreshHadHealthyInstallation = true

    nonisolated override init() {
        super.init()
    }

    override func loadPhpVersions(loadOutdated: Bool) async -> [BrewPhpFormula] {
        let environments = App.shared.container.phpEnvs!
        lastRefreshWasBusy = environments.isBusy
        lastRefreshHadHealthyInstallation = environments.cachedPhpInstallations["8.3"]?.isHealthy == true
        return await super.loadPhpVersions(loadOutdated: loadOutdated)
    }
}
