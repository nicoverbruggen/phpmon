//
//  RemovePhpVersionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class RemovePhpVersionCommand: BrewCommand {
    let formula: String
    let version: String

    init(formula: String) {
        self.version = formula
            .replacingOccurrences(of: "php@", with: "")
            .replacingOccurrences(of: "shivammathur/php/", with: "")
        self.formula = formula
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "Removing PHP \(version)..."

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "Please wait while Homebrew removes PHP \(version)..."
        ))

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) remove \(formula) --force --ignore-dependencies
            """

        do {
            try await BrewPermissionFixer().fixPermissions()
        } catch {
            return
        }

        var loggedMessages: [String] = []

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus <= 0 {
            onProgress(.create(value: 0.95, title: progressTitle, description: "Reloading PHP versions..."))
            await PhpEnvironments.detectPhpVersions()
            await MainMenu.shared.refreshActiveInstallation()
            onProgress(.create(value: 1, title: progressTitle, description: "The operation has succeeded."))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages)
        }
    }
}
