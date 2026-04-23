//
//  OnboardingWizardViewModel+Steps.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension OnboardingWizardViewModel {
    func requestDeveloperToolsInstall() async {
        outputLines = []
        state = .running

        let output = await container.shell.pipe(OnboardingWizardCommands.developerToolsInstall)
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
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else {
            state = .waitingForManualCompletion
            onDeveloperToolsRecheckFailed?()
        }
    }

    func installHomebrew() async {
        outputLines = []
        state = .running

        do {
            try await container.shell.attach(
                OnboardingWizardCommands.homebrewInstall,
                didReceiveOutput: { [weak self] text, stream in
                    Task { @MainActor in
                        self?.appendOutput(text, stream)
                    }
                },
                withTimeout: 900
            )
        } catch {
            state = .failed
            appendOutput("\nError: \(error.localizedDescription)", .stdErr)
            return
        }

        await container.shell.reloadEnvPath()
        await refreshProgress()

        if progress.homebrewInstalled {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else {
            state = .failed
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func fixPathAutomatically() async {
        outputLines = []
        state = .running

        let zshRunCommand = ZshRunCommand(container)
        appendOutput("onboarding_wizard.output.path_updating".localized, .stdOut)

        let composerResult = await zshRunCommand.addComposerPath()
        let homebrewResult = await zshRunCommand.addHomebrewPath()

        await container.shell.reloadEnvPath()
        await refreshProgress()

        if composerResult && homebrewResult && progress.pathConfigured {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else if composerResult && homebrewResult {
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
        state = progress.pathConfigured ? .idle : .waitingForManualCompletion
    }

    func installPhpComposer() async {
        outputLines = []
        state = .running

        do {
            try await container.shell.attach(
                "\(container.paths.brew) install php composer",
                didReceiveOutput: { [weak self] text, stream in
                    Task { @MainActor in
                        self?.appendOutput(text, stream)
                    }
                },
                withTimeout: 600
            )
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
}
