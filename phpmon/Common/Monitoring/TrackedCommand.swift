//
//  TrackedCommand.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

final class TrackedCommand: CommandProtocol {
    private let command: CommandProtocol
    private let commandTracker: CommandTracker

    init(command: CommandProtocol, commandTracker: CommandTracker) {
        self.command = command
        self.commandTracker = commandTracker
    }

    func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool,
        withStandardError: Bool
    ) -> String {
        let commandDescription = "\(path) \(arguments.joined(separator: " "))"
        let trackingId = commandTracker.trackFromAnyThread(commandDescription)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }

        return command.execute(
            path: path,
            arguments: arguments,
            trimNewlines: trimNewlines,
            withStandardError: withStandardError
        )
    }
}
