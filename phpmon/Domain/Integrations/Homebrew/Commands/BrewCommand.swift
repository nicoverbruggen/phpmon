//
//  BrewCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol BrewCommand {
    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws

    func getCommandTitle() -> String
}

extension BrewCommand {
    internal func reportInstallationProgress(_ text: String) -> (Double, String)? {
        if text.contains("Fetching") {
            return (0.1, "phpman.steps.fetching".localized)
        }
        if text.contains("Downloading") {
            return (0.25, "phpman.steps.downloading".localized)
        }
        if text.contains("Installing") {
            return (0.60, "phpman.steps.installing".localized)
        }
        if text.contains("Pouring") {
            return (0.80, "phpman.steps.pouring".localized)
        }
        if text.contains("Summary") {
            return (0.90, "phpman.steps.summary".localized)
        }
        return nil
    }

    internal func run(_ command: String, _ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        var loggedMessages: [String] = []

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }

                if let (number, text) = self.reportInstallationProgress(text) {
                    onProgress(.create(value: number, title: getCommandTitle(), description: text))
                }
            },
            withTimeout: .minutes(15)
        )

        if process.terminationStatus <= 0 {
            loggedMessages = []
            return
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.", log: loggedMessages)
        }
    }

    internal func checkPhpTap(_ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        if !BrewDiagnostics.installedTaps.contains("shivammathur/php") {
            let command = "brew tap shivammathur/php"
            try await run(command, onProgress)
        }

        if !BrewDiagnostics.installedTaps.contains("shivammathur/extensions") {
            let command = "brew tap shivammathur/extensions"
            try await run(command, onProgress)
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
