//
//  OnboardingStepRunner+DevTools.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    /**
     Request Apple's Developer Tools to be installed.
     */
    func requestDeveloperToolsInstall() async -> Result {
        var outputLines: [OutputLine] = []
        let output = await container.shell
            .pipe(CommandCatalog.Onboarding.commandLineToolsInstall)

        appendIfPresent(output, to: &outputLines)
        appendOutput("onboarding_wizard.output.developer_tools_requested".localized, .stdOut, to: &outputLines)

        return Result(
            state: .waitingForManualCompletion,
            outputLines: outputLines,
            progress: nil,
            alertState: nil
        )
    }

    /**
     Once the request has occurred, we need the user to click the button,
     this is to re-check if the install actually happened.
     */
    func recheckDeveloperTools() async -> Result {
        // Use the probe to check dependencies again
        let progress = await probe.detectProgress()

        // Specifically, check if developer tools are actually installed now
        if progress.developerToolsInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        // But if that falls through, we should let the user know they still need to complete the flow
        return Result(
            state: .waitingForManualCompletion,
            outputLines: OutputLine.errLines(["\n\("onboarding_wizard.output.step_not_resolved".localized)"]),
            progress: progress,
            alertState: .developerToolsIncomplete
        )
    }
}
