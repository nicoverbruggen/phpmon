//
//  HomebrewOperationManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class ModifyPhpVersionCommand: BrewCommand {
    let title: String
    let installing: [BrewPhpFormula]
    let upgrading: [BrewPhpFormula]
    let phpGuard: PhpGuard

    func getCommandTitle() -> String {
        return title
    }

    /**
     You can pass in which PHP versions need to be upgraded and which ones need to be installed.
     The process will be executed in two steps: first upgrades, then installations.
     Upgrades come first because... well, otherwise installations may very well break.
     Each version that is installed will need to be checked afterwards (if it is OK).
     */
    public init(
        title: String,
        upgrading: [BrewPhpFormula],
        installing: [BrewPhpFormula]
    ) {
        self.title = title
        self.installing = installing
        self.upgrading = upgrading
        self.phpGuard = PhpGuard()
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "Please wait..."

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "PHP Monitor is preparing Homebrew..."
        ))

        // Make sure the tap is installed
        try await self.checkPhpTap(onProgress)

        // Try to run all upgrade and installation operations
        try await self.upgradePackages(onProgress)
        try await self.installPackages(onProgress)

        // Re-check the installed versions
        await PhpEnvironments.detectPhpVersions()

        // After performing operations, attempt to run repairs if needed
        try await self.repairBrokenPackages(onProgress)

        // Finally, complete all operations
        await self.completedOperations(onProgress)
    }

    private func upgradePackages(_ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        // If no upgrades are needed, early exit
        if self.upgrading.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) upgrade \(self.upgrading.map { $0.name }.joined(separator: " "))
            """

        try await run(command, onProgress)
    }

    private func installPackages(_ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        // If no installations are needed, early exit
        if self.installing.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) install \(self.installing.map { $0.name }.joined(separator: " ")) --force
            """

        try await run(command, onProgress)
    }

    private func repairBrokenPackages(_ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        // Determine which PHP installations are considered unhealthy
        // Build a list of formulae to reinstall
        let requiringRepair = PhpEnvironments.shared
            .cachedPhpInstallations.values
            .filter({ !$0.isHealthy })
            .map { installation in
                let formula = "php@\(installation.versionNumber.short)"

                if installation.versionNumber.short == PhpEnvironments.brewPhpAlias {
                    return "php"
                }

                return formula
            }

        // If no repairs are needed, early exit
        if requiringRepair.isEmpty {
            return
        }

        // If the health comes back as negative, attempt to reinstall
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=true; \
            \(Paths.brew) reinstall \(requiringRepair.joined(separator: " ")) --force
        """

        try await run(command, onProgress)
    }

    private func completedOperations(_ onProgress: @escaping (BrewCommandProgress) -> Void) async {
        // Reload and restart PHP versions
        onProgress(.create(value: 0.95, title: self.title, description: "Reloading PHP versions..."))

        // Check which version of PHP are now installed
        await PhpEnvironments.detectPhpVersions()

        // Keep track of the currently installed version
        await MainMenu.shared.refreshActiveInstallation()

         // If a PHP version was active prior to running the operations, attempt to restore it
         if let version = phpGuard.currentVersion {
             await MainMenu.shared.switchToPhpVersionAndWait(version, silently: true)
         }

        // Also rebuild the content of the main menu
        await MainMenu.shared.rebuild()

        // Let the UI know that the installation has been completed
        onProgress(.create(
            value: 1,
            title: "Operation completed!",
            description: "The installation has succeeded."
        ))
    }
}
