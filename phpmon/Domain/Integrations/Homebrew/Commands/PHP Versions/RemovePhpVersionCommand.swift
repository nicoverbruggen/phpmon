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

    let container: Container

    // MARK: - Variables

    let formula: String
    let version: String

    /// The PHP version linked when this command was created, snapshotted on the main actor
    /// at init time. Storing the `Sendable` `String?` (instead of the non-Sendable
    /// `PhpGuard`) lets the `nonisolated` orchestration read it without hopping. (Note:
    /// under `NonisolatedNonsendingByDefault`, that orchestration runs on the *caller's*
    /// executor — usually the main actor — and stays responsive because the underlying
    /// shell APIs suspend; only explicitly `offMain`/`@concurrent` work leaves the caller.)
    let previousPhpVersion: String?

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
        self.previousPhpVersion = PhpGuard().currentVersion
    }

    nonisolated func getCommandTitle() -> String {
        return "phpman.steps.removing".localized("PHP \(version)...")
    }

    nonisolated func execute(shell: ShellProtocol, onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws {
        onProgress(.create(
            value: 0.2,
            title: getCommandTitle(),
            description: "phpman.steps.wait".localized
        ))

        let command = """
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_NO_ASK=true; \
            \(container.paths.brew) remove \(formula) --force --ignore-dependencies
            """

        do {
            try await BrewPermissionFixer(container).fixPermissions()
        } catch {
            return
        }

        let loggedMessages = Locked<[String]>([])

        let (process, _): (Process, ShellOutput)

        do {
            (process, _) = try await shell.attach(
                command,
                didReceiveOutput: { text, _ in
                    if !text.isEmpty {
                        Log.perf(text)
                        loggedMessages.withLock { $0.append(text) }
                    }
                },
                withTimeout: .minutes(5)
            )
        } catch ShellError.timedOut {
            Log.err("The `brew remove` command timed out after 5 minutes: \(command)")
            loggedMessages.withLock { $0.append("Terminated after timeout (>5 minutes) as decided by PHP Monitor.") }
            throw BrewCommandError(error: "The command timed out after 5 minutes.", log: loggedMessages.value)
        } catch {
            Log.err("Failed to execute brew command: \(command) - \(error)")
            throw BrewCommandError(error: "Failed to execute command: \(error.localizedDescription)", log: loggedMessages.value)
        }

        if process.terminationStatus == 0 {
            onProgress(.create(value: 0.95, title: getCommandTitle(), description: "phpman.steps.reloading".localized))

            await container.phpEnvs.detectPhpVersions()

            await MainMenu.shared.refreshActiveInstallation()

            if let version = previousPhpVersion {
                await MainMenu.shared.switchToPhpVersionAndWait(version, silently: true)
            }

            onProgress(.create(value: 1, title: getCommandTitle(), description: "phpman.steps.success".localized))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages.value)
        }
    }
}
