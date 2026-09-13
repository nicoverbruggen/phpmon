//
//  PhpVersionOperationFailureTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

struct PhpVersionOperationFailureTest {
    @Test(arguments: [false, true])
    func failed_operation_refreshes_installed_and_active_php_before_becoming_idle(installationRemoved: Bool) async throws {
        let configuration = TestableConfigurations.working
        let container = Container.fake(
            shell: configuration.shellOutput, files: configuration.filesystem,
            commands: configuration.commandOutput
        )

        container.preferences.cachedPreferences[.iconTypeToDisplay] = MenuBarIcon.noIcon.rawValue

        container.valet.installed = false
        container.valet.version = nil
        container.phpEnvs.homebrewPackage = HomebrewPackage(
            full_name: "php", aliases: [], installed: [],
            versions: HomebrewVersion(stable: "8.4.5", head: nil, bottle: true), linked_keg: nil
        )
        await container.phpEnvs.detectPhpVersions()
        #expect(try #require(container.phpEnvs.cachedPhpInstallations["8.3"]).isHealthy)
        #expect(try #require(container.phpEnvs.currentInstall).hasErrorState == false)

        let handler = HealthRecordingFormulaeHandler(container)
        let view = PhpVersionManagerView(formulae: handler.formulae, handler: handler)
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

    override func loadPhpVersions(loadOutdated: Bool) async -> [BrewPhpFormula] {
        let environments = container.phpEnvs!
        lastRefreshWasBusy = environments.isBusy
        lastRefreshHadHealthyInstallation = environments.cachedPhpInstallations["8.3"]?.isHealthy == true
        return await super.loadPhpVersions(loadOutdated: loadOutdated)
    }
}
