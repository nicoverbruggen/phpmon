//
//  InstallPhpVersionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class InstallPhpVersionCommand: BrewCommand {
    let formula: String
    let version: String

    init(formula: String) {
        self.version = formula
            .replacingOccurrences(of: "php@", with: "")
            .replacingOccurrences(of: "shivammathur/php/", with: "")
        self.formula = formula
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "Running Homebrew operations..."

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "Please wait while Homebrew installs PHP \(version)..."
        ))

        if formula.contains("shivammathur") && !BrewDiagnostics.installedTaps.contains("shivammathur/php") {
            await Shell.quiet("brew tap shivammathur/php")
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) install \(formula) --force
            """

        // Keep track of the current PHP version prior to executing any operations
        let phpGuard = PhpGuard()

        // Try to fix permissions
        do {
            try await BrewPermissionFixer().fixPermissions()
        } catch {
            throw BrewCommandError(error: "There was an issue fixing permissions.")
        }

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                }

                if let (number, text) = self.reportInstallationProgress(text) {
                    onProgress(.create(value: number, title: progressTitle, description: text))
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus <= 0 {
            // Reload and restart PHP versions
            onProgress(.create(value: 0.95, title: progressTitle, description: "Reloading PHP versions..."))

            // Check which version of PHP are now installed
            await PhpEnv.detectPhpVersions()

            // Keep track of the currently installed version
            await MainMenu.shared.refreshActiveInstallation()

            // If a PHP version was active prior to running the operations, attempt to restore it
            if let version = phpGuard.currentVersion {
                await MainMenu.shared.switchToAnyPhpVersion(version)
            }

            // Let the UI know that the installation has been completed
            onProgress(.create(value: 1, title: progressTitle, description: "The installation has succeeded."))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.")
        }
    }
}
