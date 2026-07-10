//
//  BrewCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol BrewCommand {
    nonisolated func execute(shell: ShellProtocol, onProgress: @escaping @Sendable (BrewCommandProgress) -> Void) async throws

    nonisolated func getCommandTitle() -> String
}

// `nonisolated` free function: a pure text-parsing helper with no mutable or main-actor
// state. It is invoked from the off-main, @Sendable `didReceiveOutput` callback. Keeping it
// as a file-scope function (rather than a method) means the callback captures nothing, so
// there is no non-Sendable `self` capture.
nonisolated internal func reportInstallationProgress(_ text: String) -> (Double, String)? {
        // Special cases: downloading a manifest is effectively fetching metadata
        if text.contains("==> Downloading") && text.contains("/manifests/") {
            return (0.1, "phpman.steps.fetching".localized)
        }

        // Logical progress evaluation (reverse order for accuracy)
        if text.contains("==> Summary") {
            return (0.90, "phpman.steps.summary".localized)
        }
        if text.contains("==> Pouring") {
            if let subject = extractContext(from: text) {
                return (0.80, "phpman.steps.pouring".localized + "\n(\(subject))")
            }
            return (0.80, "phpman.steps.pouring".localized)
        }
        if text.contains("==> Installing") {
            if let subject = extractContext(from: text) {
                return (0.60, "phpman.steps.installing_package".localized + "\n(\(subject))")
            }
            return (0.60, "phpman.steps.installing_package".localized)
        }
        if text.contains("==> Downloading") {
            if let subject = extractContext(from: text) {
                return (0.25, "phpman.steps.downloading".localized + "\n(\(subject))")
            }
            return (0.25, "phpman.steps.downloading".localized)
        }
        if text.contains("==> Fetching") {
            return (0.1, "phpman.steps.fetching".localized)
        }
        return nil
    }

    // `nonisolated`: pure regex helper, called transitively from the off-main callback.
    nonisolated internal func extractContext(from text: String) -> String? {
        var pattern = #""#
        if text.contains("==> Fetching") {
            pattern = #"==> Fetching (\S+)"#
        }
        if text.contains("==> Downloading") {
            pattern = #"==> Downloading (\S+)"#
        }
        if text.contains("==> Installing") {
            pattern = #"==> Installing (\S+)"#
        }
        if text.contains("==> Pouring") {
            pattern = #"==> Pouring (\S+)"#
        }

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let formulaRange = Range(match.range(at: 1), in: text) {
                return String(text[formulaRange])
            }
        }

        return nil
    }

extension BrewCommand {
    nonisolated internal func run(
        shell: ShellProtocol,
        _ command: String,
        _ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void
    ) async throws {
        // `Locked` (a lock-guarded, @unchecked Sendable box) is the right tool here:
        // `didReceiveOutput` is a *synchronous* @Sendable callback invoked off the main
        // actor, so an `actor` collector (whose `append` would be `async`) cannot be
        // awaited from inside it. The lock keeps the accumulation data-race free.
        let loggedMessages = Locked<[String]>([])

        // Snapshot the title on the main actor so the off-main callback captures an
        // immutable `String` instead of calling the main-actor `getCommandTitle()`.
        let commandTitle = getCommandTitle()

        let (process, _): (Process, ShellOutput)

        do {
            (process, _) = try await shell.attach(
                command,
                didReceiveOutput: { text, _ in
                    if !text.isEmpty {
                        Log.perf(text)
                        loggedMessages.withLock { $0.append(text) }
                    }

                    if let (number, description) = reportInstallationProgress(text) {
                        onProgress(.create(value: number, title: commandTitle, description: description))
                    }
                },
                withTimeout: .minutes(15)
            )
        } catch ShellError.timedOut {
            // Possible if the brew command times out
            Log.err("The `brew` command timed out after 15 minutes: \(command)")
            loggedMessages.withLock { $0.append("Terminated after timeout (>15 minutes) as decided by PHP Monitor.") }
            throw BrewCommandError(error: "The command timed out after 15 minutes.", log: loggedMessages.value)
        } catch {
            // Possible if the async continuation fails
            Log.err("Failed to execute brew command: \(command) - \(error)")
            throw BrewCommandError(error: "Failed to execute command: \(error.localizedDescription)", log: loggedMessages.value)
        }

        // Finally, even if we got the command to execute, let's check the termination status
        if process.terminationStatus == 0 {
            loggedMessages.value = []
            return
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages.value)
        }
    }

    nonisolated internal func checkPhpTap(
        shell: ShellProtocol,
        _ onProgress: @escaping @Sendable (BrewCommandProgress) -> Void
    ) async throws {
        let supportsTrust = await BrewDiagnostics.shared.supportsTapTrust()

        let commands: [ConditionalCommand] = [
            .command("brew tap \(Constants.Taps.php)"),
            .command("brew trust --tap \(Constants.Taps.php)", when: supportsTrust),
            .command("brew tap \(Constants.Taps.extensions)"),
            .command("brew trust --tap \(Constants.Taps.extensions)", when: supportsTrust)
        ]

        for command in commands.included {
            try await run(shell: shell, command, onProgress)
        }
    }
}

// `nonisolated` + `Sendable`: an immutable value type that is constructed inside the
// off-main `didReceiveOutput` callback and handed to the progress reporter, so it must
// cross isolation boundaries freely.
nonisolated struct BrewCommandProgress: Sendable {
    let value: Double
    let title: String
    let description: String

    public static func create(value: Double, title: String, description: String) -> BrewCommandProgress {
        return BrewCommandProgress(value: value, title: title, description: description)
    }
}

// `nonisolated` + `Sendable`: an error value thrown from async command execution and read
// (`.log`) by callers on the main actor; it must be sendable across those boundaries.
nonisolated struct BrewCommandError: Error, Sendable {
    let error: String
    let log: [String]
}
