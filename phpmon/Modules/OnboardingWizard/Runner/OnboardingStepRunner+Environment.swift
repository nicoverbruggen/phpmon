//
//  OnboardingStepRunner+Environment.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    /**
     Fixing the PATH means making it ready for PHP Monitor.

     - Adding PHP Monitor's `bin` directory to the PATH in `.zshrc`.
     - Adding Composer's `bin` directory to the PATH in `.zshrc`.
     - Adding Homebrew's `bin` directory to the PATH in `.zshrc`.
     */

    func fixPathAutomatically() async -> Result { // TODO: Perhaps rename this to "updatePathAutomatically"?
        let zshRunCommand = ZshRunCommand(container)
        var outputLines = OutputLine.outLines(["onboarding_wizard.output.path_updating".localized])

        let phpMonitorResult = await zshRunCommand.addPhpMonitorBinPath()
        let composerResult = await zshRunCommand.addComposerBinPath()
        let homebrewResult = await zshRunCommand.addHomebrewBinPath()

        await container.shell.reloadEnvPath()
        let progress = await probe.detectProgress()
        let allFilesUpdated = phpMonitorResult && composerResult && homebrewResult

        // ----------------------------------------------------------------------------
        // A. Ideally, all files have been updated and the PATH is marked as configured
        // ----------------------------------------------------------------------------
        if allFilesUpdated && progress.pathConfigured {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        // ----------------------------------------------------------------------------
        // B. Files were updated but the shell needs to be reloaded
        //    (requires manual intervention from the user)
        // ----------------------------------------------------------------------------
        if allFilesUpdated {
            // TODO: Verify that conditions under which this scenario is valid? Might need to remove this!
            appendOutput("onboarding_wizard.output.path_reopen_shell".localized, .stdOut, to: &outputLines)

            return Result(
                state: .waitingForManualCompletion,
                outputLines: outputLines,
                progress: progress,
                alertState: nil
            )
        }

        // ----------------------------------------------------------------------------
        // C. Fall through case: step has not been resolved
        //    (requires manual intervention from the user)
        // ----------------------------------------------------------------------------
        appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr, to: &outputLines)

        return Result(
            state: .failed,
            outputLines: outputLines,
            progress: progress,
            alertState: nil
        )
    }

    /**
     Forces the user's PATH to be re-checked.
     Normally only applicable when not using `.zshrc` (which is updated automatically).
     */
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
