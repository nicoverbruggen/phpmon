//
//  OnboardingStepRunner+Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    func installValet(
        didReceiveOutput: (@Sendable (OutputLine) -> Void)?
    ) async -> Result {
        container.paths.detectBinaryPaths()

        let brew = container.paths.brew
        let composer = container.paths.composer ?? "composer"

        // Composer's shim and script are both used to run the initial install
        // Once this install concludes, a symlink in Homebrew's bin directory becomes what PHP Monitor calls
        let composerValetShim = "\(container.paths.homePath)/.composer/vendor/bin/valet"
        let composerValetScript = "\(container.paths.homePath)/.composer/vendor/laravel/valet/valet"

        let collector = Locked<[OutputLine]>([])
        var sudoersInstalled = false
        var installError: Error?
        var alertState: OnboardingAlertState?

        do {
            let installScript = CommandCatalog.Onboarding.makeValetSudoersInstallScript(
                forScriptAt: composerValetScript
            )

            _ = try await container.privilegedCommandRunner.runSimpleShellAsAdmin(
                installScript,
                reason: .onboardingValetTemporarySudoersInstall
            )
            sudoersInstalled = true

            for command in CommandCatalog.Onboarding.valetInstall(
                using: brew,
                composer: composer,
                valet: composerValetShim
            ) {
                try await attachStreaming(
                    command,
                    collector: collector,
                    didReceiveOutput: didReceiveOutput
                )
            }

            try await attachStreaming(
                CommandCatalog.Onboarding.valetTrust(using: composerValetShim),
                collector: collector,
                didReceiveOutput: didReceiveOutput
            )
        } catch {
            installError = error
        }

        if sudoersInstalled {
            do {
                _ = try await container.privilegedCommandRunner.runSimpleShellAsAdmin(
                    CommandCatalog.Onboarding.valetSudoersCleanupCommand,
                    reason: .onboardingValetTemporarySudoersCleanup
                )
            } catch {
                Log.warn("Failed to remove temporary Valet sudoers entry after onboarding: \(error)")
                alertState = .valetSudoersCleanupFailed(
                    command: CommandCatalog.Onboarding.valetSudoersCleanupCommand
                )
            }
        }

        if let installError {
            if isUserDeniedAdminPrivilegeError(installError) {
                collector.withLock {
                    $0.append(OutputLine(
                        text: "\n\("onboarding_wizard.output.valet_admin_access_denied".localized)",
                        stream: .stdErr
                    ))
                }
            } else {
                collector.withLock {
                    $0.append(OutputLine(
                        text: "\nError: \(installError.localizedDescription)",
                        stream: .stdErr
                    ))
                }
            }

            return Result(
                state: .failed,
                outputLines: collector.value,
                progress: nil,
                alertState: alertState
            )
        }

        let progress = await probe.detectProgress()

        if progress.valetInstalled && progress.valetTrusted {
            return Result(
                state: .idle,
                outputLines: [],
                progress: progress,
                alertState: alertState
            )
        }

        collector.withLock {
            $0.append(OutputLine(
                text: "\n\("onboarding_wizard.output.step_not_resolved".localized)",
                stream: .stdErr
            ))
        }

        return Result(
            state: .failed,
            outputLines: collector.value,
            progress: progress,
            alertState: alertState
        )
    }

    private func isUserDeniedAdminPrivilegeError(_ error: Error) -> Bool {
        return (error as? AdminPrivilegeError)?.kind == .userDenied
    }
}
