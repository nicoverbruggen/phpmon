//
//  OnboardingStepRunner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct OnboardingStepRunner {
    struct Result {
        let state: OnboardingRunState
        let outputLines: [OutputLine]
        let progress: OnboardingProgress?
        let alertState: OnboardingAlertState?
    }

    let container: Container
    let probe: OnboardingEnvironmentProbe

    func run(
        _ action: OnboardingAction,
        didReceiveOutput: (@Sendable (OutputLine) -> Void)? = nil
    ) async -> Result {
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
            return await installPhpComposer(didReceiveOutput: didReceiveOutput)
        case .installValet:
            return await installValet(didReceiveOutput: didReceiveOutput)
        case .startSetup, .continueToStartup:
            return Result(state: .idle, outputLines: [], progress: nil, alertState: nil)
        }
    }

    func appendIfPresent(_ output: ShellOutput, to outputLines: inout [OutputLine]) {
        if !output.out.isEmpty {
            appendOutput(output.out, .stdOut, to: &outputLines)
        }

        if !output.err.isEmpty {
            appendOutput(output.err, .stdErr, to: &outputLines)
        }
    }

    func appendOutput(
        _ text: String,
        _ stream: ShellStream,
        to outputLines: inout [OutputLine]
    ) {
        outputLines.append(OutputLine(text: text, stream: stream))
    }

    func attachStreaming(
        _ command: String,
        collector: Locked<[OutputLine]>,
        didReceiveOutput: (@Sendable (OutputLine) -> Void)? = nil,
        timeout: TimeInterval = 600
    ) async throws {
        try await container.shell.attach(
            command,
            didReceiveOutput: { text, stream in
                let line = OutputLine(text: text, stream: stream)

                collector.withLock {
                    $0.append(line)
                }

                didReceiveOutput?(line)
            },
            withTimeout: timeout
        )
    }
}
