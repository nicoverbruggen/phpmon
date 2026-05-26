//
//  OnboardingStepRunner+Environment.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    func fixPathAutomatically() async -> Result {
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

    func recheckPath() async -> Result {
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
}
