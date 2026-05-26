//
//  OnboardingStepRunner+Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Foundation

extension OnboardingStepRunner {
    var isSimulatingShellEnvironment: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }

    func requestHomebrewInstall() async -> Result {
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

    func recheckHomebrew() async -> Result {
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
}
