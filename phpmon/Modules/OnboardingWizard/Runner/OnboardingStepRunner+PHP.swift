//
//  OnboardingStepRunner+PHP.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    /**
     Automatically installs PHP and Composer via Homebrew.
     */
    func installPhpComposer(
        didReceiveOutput: (@Sendable (OutputLine) -> Void)?
    ) async -> Result {
        // We're attaching some streaming output. To ensure there's no contention, we use `Locked`.
        // In the future, perhaps it makes sense to switch to an `actor` instead.
        let collector = Locked<[OutputLine]>([])

        do {
            let brew = container.paths.brew
            let supportsTrust = await BrewDiagnostics(container).supportsTapTrust()

            let commands: [ConditionalCommand] = [
                .command("\(brew) tap \(Constants.Taps.php)"),
                .command("\(brew) trust --tap \(Constants.Taps.php)", when: supportsTrust),
                .command("\(brew) tap \(Constants.Taps.extensions)"),
                .command("\(brew) trust --tap \(Constants.Taps.extensions)", when: supportsTrust),
                .command(CommandCatalog.Onboarding.phpComposerInstall(using: brew))
            ]

            // Attempt to install PHP and Composer via Homebrew. We will stream the output,
            // so the user can see what's going on, since this can take a bit of time!
            for command in commands.included {
                try await attachStreaming(command, collector: collector, didReceiveOutput: didReceiveOutput)
            }
        } catch {
            // If something goes wrong, we should append the error to the list of lines.
            collector.withLock {
                $0.append(OutputLine(text: "\nError: \(error.localizedDescription)", stream: .stdErr))
            }

            // And we should also quit here; after all, the operation explicitly failed!
            return Result(
                state: .failed,
                outputLines: collector.value,
                progress: nil,
                alertState: nil
            )
        }

        // If things did not break, we should verify that the install actually worked.
        let progress = await probe.detectProgress()

        // ----------------------------------------------------------------------------
        // A. Dependencies are installed correctly; early exit!
        // ----------------------------------------------------------------------------

        if progress.phpInstalled && progress.composerInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        // ----------------------------------------------------------------------------
        // B. Dependencies aren't installed correctly.
        // ----------------------------------------------------------------------------

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
}
