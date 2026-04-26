//
//  OnboardingWizardViewModel+Steps.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit

extension OnboardingWizardViewModel {
    private var shouldSimulateManualHomebrewInstall: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }

    private var shouldSimulatePrivilegedCommands: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }

    func requestDeveloperToolsInstall() async {
        outputLines = []
        state = .running

        let output = await container.shell.pipe(Toolchain.Commands.developerToolsInstall)
        if !output.out.isEmpty {
            appendOutput(output.out, .stdOut)
        }
        if !output.err.isEmpty {
            appendOutput(output.err, .stdErr)
        }

        hasTriggeredDeveloperToolsInstall = true
        state = .waitingForManualCompletion
        appendOutput("onboarding_wizard.output.developer_tools_requested".localized, .stdOut)
    }

    func recheckDeveloperTools() async {
        state = .running
        await refreshProgress()

        if progress.developerToolsInstalled {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
            onDeveloperToolsRecheckFailed?()
        }
    }

    func requestHomebrewInstall() async {
        outputLines = []
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(Toolchain.Commands.homebrewInstall, forType: .string)

        if shouldSimulateManualHomebrewInstall {
            let output = container.shell.sync(Toolchain.Commands.homebrewInstall)
            if !output.out.isEmpty {
                appendOutput(output.out, .stdOut)
            }
            if !output.err.isEmpty {
                appendOutput(output.err, .stdErr)
            }
        }

        hasTriggeredHomebrewInstall = true
        state = .waitingForManualCompletion
        appendOutput("onboarding_wizard.output.homebrew_command_copied".localized, .stdOut)
    }

    func recheckHomebrew() async {
        state = .running
        await container.shell.reloadEnvPath()
        await refreshProgress()

        if progress.homebrewInstalled {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func fixPathAutomatically() async {
        outputLines = []
        state = .running

        let zshRunCommand = ZshRunCommand(container)
        appendOutput("onboarding_wizard.output.path_updating".localized, .stdOut)

        let phpMonitorResult = await zshRunCommand.addPhpMonitorBinPath()
        let composerResult = await zshRunCommand.addComposerBinPath()
        let homebrewResult = await zshRunCommand.addHomebrewBinPath()

        await container.shell.reloadEnvPath()
        await refreshProgress()

        if phpMonitorResult && composerResult && homebrewResult && progress.pathConfigured {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else if phpMonitorResult && composerResult && homebrewResult {
            state = .waitingForManualCompletion
            appendOutput("onboarding_wizard.output.path_reopen_shell".localized, .stdOut)
        } else {
            state = .failed
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func recheckPath() async {
        state = .running
        await container.shell.reloadEnvPath()
        await refreshProgress()

        if progress.pathConfigured {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func installPhpComposer() async {
        outputLines = []
        state = .running

        do {
            for command in Toolchain.Commands.phpComposerInstall(using: container.paths.brew) {
                try await container.shell.attach(
                    command,
                    didReceiveOutput: { [weak self] text, stream in
                        Task { @MainActor in
                            self?.appendOutput(text, stream)
                        }
                    },
                    withTimeout: 600
                )
            }
        } catch {
            state = .failed
            appendOutput("\nError: \(error.localizedDescription)", .stdErr)
            return
        }

        await refreshProgress()

        if progress.phpInstalled && progress.composerInstalled {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else {
            state = .failed
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func installValet() async {
        outputLines = []
        state = .running

        container.paths.detectBinaryPaths()
        let brew = container.paths.brew
        let composer = container.paths.composer ?? "composer"

        do {
            for command in Toolchain.Commands.valetInstall(
                using: brew,
                composer: composer,
                valet: "valet"
            ) {
                try await container.shell.attach(
                    command,
                    didReceiveOutput: { [weak self] text, stream in
                        Task { @MainActor in
                            self?.appendOutput(text, stream)
                        }
                    },
                    withTimeout: 600
                )
            }

            let valet = container.paths.valet

            if shouldSimulatePrivilegedCommands {
                let output = await container.shell.pipe(Toolchain.Commands.valetTrust(using: valet))
                if !output.out.isEmpty {
                    appendOutput(output.out, .stdOut)
                }
                if !output.err.isEmpty {
                    appendOutput(output.err, .stdErr)
                }
            } else {
                let output = try AppleScript.runShellAsAdmin(Toolchain.Commands.valetTrust(using: valet))
                if !output.isEmpty {
                    appendOutput(output, .stdOut)
                }
            }
        } catch {
            state = .failed
            appendOutput("\nError: \(error.localizedDescription)", .stdErr)
            return
        }

        await refreshProgress()

        if progress.valetInstalled && progress.valetTrusted {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else {
            state = .failed
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }
}
