//
//  HomebrewOperationManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class InstallAndUpgradeCommand: BrewCommand {

    let title: String
    let installing: [BrewFormula]
    let upgrading: [BrewFormula]
    let phpGuard: PhpGuard

    /**
     You can pass in which PHP versions need to be upgraded and which ones need to be installed.
     The process will be executed in two steps: first upgrades, then installations.
     Upgrades come first because... well, otherwise installations may very well break.
     Each version that is installed will need to be checked afterwards (if it is OK).
     */
    public init(
        title: String,
        upgrading: [BrewFormula],
        installing: [BrewFormula]
    ) {
        self.title = title
        self.installing = installing
        self.upgrading = upgrading
        self.phpGuard = PhpGuard()
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        // Try to run all upgrade and installation operations
        try await self.upgradePackages(onProgress)
        try await self.installPackages(onProgress)

        // Re-check the installed versions
        await PhpEnv.detectPhpVersions()

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
        let requiringRepair = PhpEnv.shared
            .cachedPhpInstallations.values
            .filter({ !$0.isHealthy })
            .map { installation in
                let formula = "php@\(installation.versionNumber.short)"

                if installation.versionNumber.short == PhpEnv.brewPhpAlias {
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
            \(Paths.brew) reinstall \(requiringRepair.joined(separator: " ")) --force
        """

        try await run(command, onProgress)
    }

    private func run(_ command: String, _ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        var loggedMessages: [String] = []

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }

                if let (number, text) = self.reportInstallationProgress(text) {
                    onProgress(.create(value: number, title: self.title, description: text))
                }
            },
            withTimeout: .minutes(15)
        )

        if process.terminationStatus <= 0 {
            loggedMessages = []
            return
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages)
        }
    }

    private func completedOperations(_ onProgress: @escaping (BrewCommandProgress) -> Void) async {
        // Reload and restart PHP versions
        onProgress(.create(value: 0.95, title: self.title, description: "Reloading PHP versions..."))

        // Check which version of PHP are now installed
        await PhpEnv.detectPhpVersions()

        // Keep track of the currently installed version
        await MainMenu.shared.refreshActiveInstallation()

         // If a PHP version was active prior to running the operations, attempt to restore it
         if let version = phpGuard.currentVersion {
             await MainMenu.shared.switchToAnyPhpVersion(version, silently: true)
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
