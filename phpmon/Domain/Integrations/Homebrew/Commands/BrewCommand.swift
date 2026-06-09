//
//  BrewCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol BrewCommand {
    func execute(shell: ShellProtocol, onProgress: @escaping (BrewCommandProgress) -> Void) async throws

    func getCommandTitle() -> String
}

extension BrewCommand {
    internal func reportInstallationProgress(_ text: String) -> (Double, String)? {
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

    internal func extractContext(from text: String) -> String? {
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

    internal func run(
        shell: ShellProtocol,
        _ command: String,
        _ onProgress: @escaping (BrewCommandProgress) -> Void
    ) async throws {
        let loggedMessages = Locked<[String]>([])
        let (process, _): (Process, ShellOutput)

        do {
            (process, _) = try await shell.attach(
                command,
                didReceiveOutput: { text, _ in
                    if !text.isEmpty {
                        Log.perf(text)
                        loggedMessages.withLock { $0.append(text) }
                    }

                    if let (number, text) = self.reportInstallationProgress(text) {
                        onProgress(.create(value: number, title: getCommandTitle(), description: text))
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

    internal func checkPhpTap(
        shell: ShellProtocol,
        _ onProgress: @escaping (BrewCommandProgress) -> Void
    ) async throws {
        let diagnostics = BrewDiagnostics.shared

        for command in await diagnostics.requiredPhpTapCommands(using: "brew").included {
            try await run(shell: shell, command, onProgress)
        }
    }
}

struct BrewCommandProgress {
    let value: Double
    let title: String
    let description: String

    public static func create(value: Double, title: String, description: String) -> BrewCommandProgress {
        return BrewCommandProgress(value: value, title: title, description: description)
    }
}

struct BrewCommandError: Error {
    let error: String
    let log: [String]
}
