//
//  OnboardingStepRunner+DevTools.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    func requestDeveloperToolsInstall() async -> Result {
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

    func recheckDeveloperTools() async -> Result {
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
}
