//
//  HomebrewOperationManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class ModifyPhpVersionCommand: BrewCommand {

    // MARK: - Container

    let container: Container

    // MARK: - Variables

    let title: String
    let installing: [BrewPhpFormula]
    let upgrading: [BrewPhpFormula]

    /// The PHP version linked when this command was created, snapshotted on the main actor
    /// at init time. Storing the `Sendable` `String?` (instead of the non-Sendable
    /// `PhpGuard`) lets the `nonisolated` orchestration read it without hopping. (Note:
    /// under `NonisolatedNonsendingByDefault`, that orchestration runs on the *caller's*
    /// executor — usually the main actor — and stays responsive because the underlying
    /// shell APIs suspend; only explicitly `runBlocking`/`@concurrent` work leaves the caller.)
    let previousPhpVersion: String?

    // MARK: - Methods

    nonisolated func getCommandTitle() -> String {
        return title
    }

    /**
     You can pass in which PHP versions need to be upgraded and which ones need to be installed.
     The process will be executed in two steps: first upgrades, then installations.
     
     Upgrades come first because... well, otherwise installations may very well break.
     Each version that is installed will need to be checked afterwards. Installing a
     newer formula may break other PHP installations, which in turn need to be fixed.

     - Important: If any PHP formula is a major upgrade that causes a PHP "version" to be
       uninstalled, this is remedied by running `upgradeMainPhpFormula()`. This process
       will ensure that the upgrade is applied, but the also that old version is
       re-installed and linked again.
     */
    public init(
        _ container: Container,
        title: String,
        upgrading: [BrewPhpFormula],
        installing: [BrewPhpFormula]
    ) {
        self.container = container
        self.title = title
        self.installing = installing
        self.upgrading = upgrading
        self.previousPhpVersion = PhpGuard(container: container).currentVersion
    }

    nonisolated func execute(shell: ShellProtocol, onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "phpman.steps.wait".localized

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "phpman.steps.preparing".localized
        ))

        // Determine if a formula will become unavailable
        // This is the case when `php` will be bumped to a new version
        let unavailable = upgrading.first(where: { formula in
            formula.unavailableAfterUpgrade
        })

        // Make sure the tap is installed
        try await self.checkPhpTap(shell: shell, onProgress)

        if unavailable == nil {
            // Try to run all upgrade and installation operations
            try await self.upgradePackages(onProgress)
            try await self.installPackages(onProgress)
        } else {
            // Simply upgrade `php` to the latest version
            try await self.upgradeMainPhpFormula(unavailable!, onProgress)
            await container.phpEnvs.determinePhpAlias()
        }

        // Re-check the installed versions
        await container.phpEnvs.detectPhpVersions()

        // After performing operations, attempt to run repairs if needed
        try await self.repairBrokenPackages(onProgress)

        // Finally, complete all operations
        await self.completedOperations(onProgress)
    }

    nonisolated private func upgradeMainPhpFormula(
        _ unavailable: BrewPhpFormula,
        _ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void
    ) async throws {
        // Determine which version was previously available (that will become unavailable)
        guard let short = try? VersionNumber
            .parse(unavailable.installedVersion!).short else {
            return
        }

        // Upgrade the main formula
        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_ASK=true; \
            \(container.paths.brew) upgrade php;
            \(container.paths.brew) install php@\(short);
            """

        // Run the upgrade command
        try await run(shell: container.shell, command, onProgress)
    }

    nonisolated private func upgradePackages(_ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws {
        // If no upgrades are needed, early exit
        if self.upgrading.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_ASK=true; \
            \(container.paths.brew) upgrade \(self.upgrading.map { $0.name }.joined(separator: " "))
            """

        try await run(shell: container.shell, command, onProgress)
    }

    nonisolated private func installPackages(_ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws {
        // If no installations are needed, early exit
        if self.installing.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_ASK=true; \
            \(container.paths.brew) install \(self.installing.map { $0.name }.joined(separator: " ")) --force
            """

        try await run(shell: container.shell, command, onProgress)
    }

    nonisolated private func repairBrokenPackages(_ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws {
        // Determine which PHP installations are considered unhealthy
        // Build a list of formulae to reinstall. `cachedPhpInstallations` and the
        // `PhpInstallation` values it holds are main-actor-isolated (and non-Sendable), so we
        // gather the plain `[String]` result on the main actor and hand only that back off-main.
        let container = self.container
        let requiringRepair: [String] = await MainActor.run {
            container.phpEnvs
                .cachedPhpInstallations.values
                .filter({ !$0.isHealthy })
                .map { installation in
                    let formula = "php@\(installation.versionNumber.short)"

                    if installation.versionNumber.short == container.phpEnvs.brewPhpAlias {
                        return "php"
                    }

                    return formula
                }
        }

        // If no repairs are needed, early exit
        if requiringRepair.isEmpty {
            return
        }

        // If the health comes back as negative, attempt to reinstall
        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=true; \
            export HOMEBREW_NO_ASK=true; \
            \(container.paths.brew) reinstall \(requiringRepair.joined(separator: " ")) --force
        """

        try await run(shell: container.shell, command, onProgress)
    }

    nonisolated private func completedOperations(_ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async {
        // Reload and restart PHP versions
        onProgress(.create(value: 0.95, title: self.title, description: "phpman.steps.reloading".localized))

        // Ensure all symlinks are correctly linked
        await BrewDiagnostics.shared.checkForOutdatedPhpInstallationSymlinks()

        // Check which version of PHP are now installed
        await container.phpEnvs.detectPhpVersions()

        // Keep track of the currently installed version
        await MainMenu.shared.refreshActiveInstallation()

         // If a PHP version was active prior to running the operations, attempt to restore it
         if let version = previousPhpVersion {
             await MainMenu.shared.switchToPhpVersionAndWait(version, silently: true)
         }

        // Also rebuild the content of the main menu
        await MainMenu.shared.rebuild()

        // Let the UI know that the installation has been completed
        onProgress(.create(
            value: 1,
            title: "phpman.steps.completed".localized,
            description: "phpman.steps.success".localized
        ))
    }
}
