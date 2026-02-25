//
//  StartupAlertViewModel.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct OutputLine: Identifiable {
    let id = UUID()
    let text: String
    let stream: ShellStream
}

class StartupAlertViewModel: ObservableObject {
    enum State {
        case idle
        case running
        case completed
    }

    @Published var state: State = .idle
    @Published var outputLines: [OutputLine] = []

    let check: EnvironmentCheck

    /// Callback to dismiss the window with a result
    var onComplete: ((Startup.EnvironmentAlertOutcome) -> Void)?

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

    @MainActor
    func runFix() {
        guard let fixCommand = check.fixCommand else { return }
        state = .running
        outputLines = []

        Task {
            do {
                try await fixCommand(App.shared.container) { [weak self] text, stream in
                    DispatchQueue.main.async {
                        self?.outputLines.append(OutputLine(text: text, stream: stream))
                    }
                }

                // Fix completed — re-run the check
                let stillFails = await check.succeeds()
                await MainActor.run {
                    if !stillFails {
                        // Check still fails after fix
                        self.state = .idle
                        self.outputLines.append(
                            OutputLine(text: "\nFix did not resolve the issue.", stream: .stdErr)
                        )
                    } else {
                        // Check passed
                        self.onComplete?(.shouldRunFix)
                    }
                }
            } catch {
                await MainActor.run {
                    self.outputLines.append(
                        OutputLine(text: "\nError: \(error.localizedDescription)", stream: .stdErr)
                    )
                    self.state = .idle
                }
            }
        }
    }

    func quit() {
        exit(1)
    }

    func retry() {
        onComplete?(.shouldRetryStartup)
    }
}
