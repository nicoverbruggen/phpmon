//
//  StartupAlertViewModel.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

class StartupAlertViewModel: ObservableObject {
    enum State {
        case idle
        case running
        case completed
    }

    /// The actual check that is associated with this alert modal
    let check: EnvironmentCheck

    /// Callback to dismiss the window with a result
    var onComplete: ((Startup.EnvironmentAlertOutcome) -> Void)?

    @Published var state: State = .idle
    @Published var outputLines: [OutputLine] = []

    init(check: EnvironmentCheck) {
        self.check = check
        self.state = check.fixCommand != nil ? .idle : .completed
    }

    init(check: EnvironmentCheck, state: State, outputLines: [OutputLine] = []) {
        self.check = check
        self.state = state
        self.outputLines = outputLines
    }

    var hasFix: Bool {
        return check.fixCommand != nil
    }

    /**
     Attempt to run a fix. When a fix is executed, terminal output will be displayed in the alert,
     by appending to outputLines, which will differentiate between stdOut or stdErr output.

     After the execution of the fix, the check is re-executed and depending on the success state
     the user can retry all checks again or the app silently continues on to the next check.
     */
    @MainActor func runFix() {
        // Ensure a fix is available, or return
        guard let fixCommand = check.fixCommand else { return }

        // Initial state
        outputLines = []
        state = .running

        // Dispatch async fix
        Task {
            do {
                // Run the command to fix the
                try await fixCommand(App.shared.container) { [weak self] text, stream in
                    DispatchQueue.main.async {
                        self?.outputLines.append(OutputLine(text: text, stream: stream))
                    }
                }

                // Fix completed — re-run the check
                let didSucceed = await check.succeeds()

                await MainActor.run {
                    if !didSucceed {
                        fail() // After re-running the check, we still failed
                    } else {
                        pass() // After re-running the check, the check is OK
                    }
                }

                if await MainActor.run(body: { self.state }) == .completed {
                    // We will wait a few seconds so the user can see the success
                    await delay(seconds: 3)

                    // Fire completion handler on main thread
                    nextCheck()
                }
            } catch {
                // If something goes wrong, show the error
                errorAndIdle(error)
            }
        }
    }

    // MARK: - Fix Outcomes

    @MainActor private func pass() {
        self.state = .completed
        self.outputLines.append(OutputLine(text: "\nFix applied successfully!", stream: .stdOut))
    }

    @MainActor private func fail() {
        self.state = .idle
        self.outputLines.append(OutputLine(text: "\nFix did not resolve the issue.", stream: .stdErr))
    }

    @MainActor private func errorAndIdle(_ error: Error) {
        self.state = .idle
        self.outputLines.append(OutputLine(text: "\nError: \(error.localizedDescription)", stream: .stdErr))
    }

    // MARK: - Alert Outcomes

    /// The user has chosen to quit the app.
    @MainActor func quit() {
        exit(1)
    }

    /// This check has passed, and we will continue to the next one automatically.
    @MainActor func nextCheck() {
        onComplete?(.shouldContinue)
    }

    /// This check has failed, and we will need to retry our startup flow from scratch.
    @MainActor func retryAllChecks() {
        onComplete?(.shouldRetryStartup)
    }
}
