//
//  OnboardingStepRunner+PHP.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingStepRunner {
    func installPhpComposer(
        didReceiveOutput: (@Sendable (OutputLine) -> Void)?
    ) async -> Result {
        let collector = Locked<[OutputLine]>([])

        do {
            for command in CommandCatalog.Onboarding.phpComposerInstall(using: container.paths.brew) {
                try await attachStreaming(
                    command,
                    collector: collector,
                    didReceiveOutput: didReceiveOutput
                )
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
}
