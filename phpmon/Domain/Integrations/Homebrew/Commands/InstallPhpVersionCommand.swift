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
        let progressTitle = "Installing PHP \(version)..."

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

        #error("Must keep track of the active PHP version (if applicable)")

        do {
            try await BrewPermissionFixer().fixPermissions()
        } catch {
            return
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
            onProgress(.create(value: 0.95, title: progressTitle, description: "Reloading PHP versions..."))
            await PhpEnv.detectPhpVersions()
            await MainMenu.shared.refreshActiveInstallation()
            #error("Must restore active PHP installation (if applicable)")
            onProgress(.create(value: 1, title: progressTitle, description: "The installation has succeeded."))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.")
        }
    }

    private func reportInstallationProgress(_ text: String) -> (Double, String)? {
        if text.contains("Fetching") {
            return (0.1, "Fetching...")
        }
        if text.contains("Downloading") {
            return (0.25, "Downloading package data...")
        }
        if text.contains("Already downloaded") || text.contains("Downloaded") {
            return (0.50, "Downloaded!")
        }
        if text.contains("Installing") {
            return (0.60, "Installing...")
        }
        if text.contains("Pouring") {
            return (0.80, "Pouring...")
        }
        if text.contains("Summary") {
            return (0.90, "The installation is done!")
        }
        return nil
    }
}
