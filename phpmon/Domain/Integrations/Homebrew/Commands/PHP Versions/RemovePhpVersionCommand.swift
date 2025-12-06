//
//  RemovePhpVersionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class RemovePhpVersionCommand: BrewCommand {

    // MARK: - Container

    var container: Container

    // MARK: - Variables

    let formula: String
    let version: String
    let phpGuard: PhpGuard

    // MARK: - Methods

    init(
        _ container: Container,
        formula: String
    ) {
        self.container = container
        self.version = formula
            .replacing("php@", with: "")
            .replacing("shivammathur/php/", with: "")
        self.formula = formula
        self.phpGuard = PhpGuard()
    }

    func getCommandTitle() -> String {
        return "phpman.steps.removing".localized("PHP \(version)...")
    }

    func execute(shell: ShellProtocol, onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        onProgress(.create(
            value: 0.2,
            title: getCommandTitle(),
            description: "phpman.steps.wait".localized
        ))

        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(container.paths.brew) remove \(formula) --force --ignore-dependencies
            """

        do {
            try await BrewPermissionFixer(container).fixPermissions()
        } catch {
            return
        }

        var loggedMessages: [String] = []

        let (process, _) = try! await shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus == 0 {
            onProgress(.create(value: 0.95, title: getCommandTitle(), description: "phpman.steps.reloading".localized))

            _ = await container.phpEnvs.detectPhpVersions()

            await MainMenu.shared.refreshActiveInstallation()

            if let version = phpGuard.currentVersion {
                await MainMenu.shared.switchToPhpVersionAndWait(version, silently: true)
            }

            onProgress(.create(value: 1, title: getCommandTitle(), description: "phpman.steps.success".localized))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages)
        }
    }
}
