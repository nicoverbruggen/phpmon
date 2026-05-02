//
//  OnboardingWizardViewModel+Steps.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Foundation

struct OnboardingEnvironmentProbe {
    let container: Container

    func detectProgress() async -> OnboardingProgress {
        container.paths.detectBinaryPaths()

        let toolchain = Toolchain(container)
        let shellEnvironment = ShellEnvironment(container)
        let valetInstalled = hasValetBinary() && hasValetConfiguration()
        let valetTrusted = await hasValetTrustConfiguration()

        return OnboardingProgress(
            developerToolsInstalled: await toolchain.status(.commandLineTools).installed,
            homebrewInstalled: await toolchain.status(.homebrew).installed,
            pathConfigured: shellEnvironment.hasRequiredOnboardingPaths(),
            phpInstalled: await toolchain.status(.php).installed,
            composerInstalled: await toolchain.status(.composer).installed,
            valetInstalled: valetInstalled,
            valetTrusted: valetTrusted
        )
    }

    private func hasValetBinary() -> Bool {
        return container.filesystem.fileExists(container.paths.valet)
            || container.filesystem.fileExists("~/.composer/vendor/bin/valet")
    }

    private func hasValetConfiguration() -> Bool {
        return container.filesystem.directoryExists("~/.config/valet")
    }

    private func hasValetTrustConfiguration() async -> Bool {
        let brewTrusted = await container.shell
            .pipe(CommandCatalog.Onboarding.checkSudoersBrew)
            .out.contains(container.paths.brew)
        let valetTrusted = await container.shell
            .pipe(CommandCatalog.Onboarding.checkSudoersValet)
            .out.contains(container.paths.valet)

        return brewTrusted && valetTrusted
    }
}

struct OnboardingStepRunner {
    struct Result {
        let state: OnboardingRunState
        let outputLines: [OutputLine]
        let progress: OnboardingProgress?
        let alertState: OnboardingAlertState?
    }

    let container: Container
    let probe: OnboardingEnvironmentProbe

    private var isSimulatingShellEnvironment: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }

    func run(_ action: OnboardingAction) async -> Result {
        switch action {
        case .installDeveloperTools:
            return await requestDeveloperToolsInstall()
        case .recheckDeveloperTools:
            return await recheckDeveloperTools()
        case .installHomebrew:
            return await requestHomebrewInstall()
        case .recheckHomebrew:
            return await recheckHomebrew()
        case .fixPathAutomatically:
            return await fixPathAutomatically()
        case .recheckPath:
            return await recheckPath()
        case .installPhpComposer:
            return await installPhpComposer()
        case .installValet:
            return await installValet()
        case .startSetup, .continueToStartup:
            return Result(state: .idle, outputLines: [], progress: nil, alertState: nil)
        }
    }

    private func requestDeveloperToolsInstall() async -> Result {
        var outputLines: [OutputLine] = []
        let output = await container.shell.pipe(CommandCatalog.Onboarding.commandLineToolsInstall)
        appendIfPresent(output, to: &outputLines)
        appendOutput("onboarding_wizard.output.developer_tools_requested".localized, .stdOut, to: &outputLines)

        return Result(
            state: .waitingForManualCompletion,
            outputLines: outputLines,
            progress: nil,
            alertState: nil
        )
    }

    private func recheckDeveloperTools() async -> Result {
        let progress = await probe.detectProgress()

        if progress.developerToolsInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        return Result(
            state: .waitingForManualCompletion,
            outputLines: [OutputLine(
                text: "\n\("onboarding_wizard.output.step_not_resolved".localized)",
                stream: .stdErr
            )],
            progress: progress,
            alertState: .developerToolsIncomplete
        )
    }

    private func requestHomebrewInstall() async -> Result {
        var outputLines: [OutputLine] = []

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(CommandCatalog.Onboarding.homebrewInstall, forType: .string)

        if isSimulatingShellEnvironment {
            let output = container.shell.sync(CommandCatalog.Onboarding.homebrewInstall)
            appendIfPresent(output, to: &outputLines)
        }

        appendOutput("onboarding_wizard.output.homebrew_command_copied".localized, .stdOut, to: &outputLines)

        return Result(
            state: .waitingForManualCompletion,
            outputLines: outputLines,
            progress: nil,
            alertState: nil
        )
    }

    private func recheckHomebrew() async -> Result {
        await container.shell.reloadEnvPath()
        let progress = await probe.detectProgress()

        if progress.homebrewInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        return Result(
            state: .waitingForManualCompletion,
            outputLines: [OutputLine(
                text: "\n\("onboarding_wizard.output.step_not_resolved".localized)",
                stream: .stdErr
            )],
            progress: progress,
            alertState: nil
        )
    }

    private func fixPathAutomatically() async -> Result {
        let zshRunCommand = ZshRunCommand(container)
        var outputLines: [OutputLine] = [
            OutputLine(
                text: "onboarding_wizard.output.path_updating".localized,
                stream: .stdOut
            )
        ]

        let phpMonitorResult = await zshRunCommand.addPhpMonitorBinPath()
        let composerResult = await zshRunCommand.addComposerBinPath()
        let homebrewResult = await zshRunCommand.addHomebrewBinPath()

        await container.shell.reloadEnvPath()
        let progress = await probe.detectProgress()

        let allFilesUpdated = phpMonitorResult && composerResult && homebrewResult

        if allFilesUpdated && progress.pathConfigured {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        if allFilesUpdated {
            appendOutput("onboarding_wizard.output.path_reopen_shell".localized, .stdOut, to: &outputLines)

            return Result(
                state: .waitingForManualCompletion,
                outputLines: outputLines,
                progress: progress,
                alertState: nil
            )
        }

        appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr, to: &outputLines)

        return Result(
            state: .failed,
            outputLines: outputLines,
            progress: progress,
            alertState: nil
        )
    }

    private func recheckPath() async -> Result {
        await container.shell.reloadEnvPath()
        let progress = await probe.detectProgress()

        if progress.pathConfigured {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        return Result(
            state: .waitingForManualCompletion,
            outputLines: [OutputLine(
                text: "\n\("onboarding_wizard.output.step_not_resolved".localized)",
                stream: .stdErr
            )],
            progress: progress,
            alertState: nil
        )
    }

    private func installPhpComposer() async -> Result {
        let collector = Locked<[OutputLine]>([])

        do {
            for command in CommandCatalog.Onboarding.phpComposerInstall(using: container.paths.brew) {
                try await attachStreaming(command, collector: collector)
            }
        } catch {
            collector.withLock {
                $0.append(OutputLine(text: "\nError: \(error.localizedDescription)", stream: .stdErr))
            }

            return Result(
                state: .failed,
                outputLines: collector.value,
                progress: nil,
                alertState: nil
            )
        }

        let progress = await probe.detectProgress()

        if progress.phpInstalled && progress.composerInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
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
            alertState: nil
        )
    }

    private func installValet() async -> Result {
        container.paths.detectBinaryPaths()

        let brew = container.paths.brew
        let composer = container.paths.composer ?? "composer"
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
                try await attachStreaming(command, collector: collector)
            }

            try await attachStreaming(
                CommandCatalog.Onboarding.valetTrust(using: composerValetShim),
                collector: collector
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

    private func appendIfPresent(_ output: ShellOutput, to outputLines: inout [OutputLine]) {
        if !output.out.isEmpty {
            appendOutput(output.out, .stdOut, to: &outputLines)
        }

        if !output.err.isEmpty {
            appendOutput(output.err, .stdErr, to: &outputLines)
        }
    }

    private func appendOutput(
        _ text: String,
        _ stream: ShellStream,
        to outputLines: inout [OutputLine]
    ) {
        outputLines.append(OutputLine(text: text, stream: stream))
    }

    private func attachStreaming(
        _ command: String,
        collector: Locked<[OutputLine]>,
        timeout: TimeInterval = 600
    ) async throws {
        try await container.shell.attach(
            command,
            didReceiveOutput: { text, stream in
                collector.withLock {
                    $0.append(OutputLine(text: text, stream: stream))
                }
            },
            withTimeout: timeout
        )
    }

    private func isUserDeniedAdminPrivilegeError(_ error: Error) -> Bool {
        return (error as? AdminPrivilegeError)?.kind == .userDenied
    }
}
