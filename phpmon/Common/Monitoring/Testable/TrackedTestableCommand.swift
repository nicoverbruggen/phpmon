//
//  TrackedTestableCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

final class TrackableTestableCommand: TestableCommand {
    private let commandTracker: CommandTracker

    init(commands: [String: String], _ commandTracker: CommandTracker) {
        self.commandTracker = commandTracker
        super.init(commands: commands)
    }

    override func execute(
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

        return super.execute(
            path: path,
            arguments: arguments,
            trimNewlines: trimNewlines,
            withStandardError: withStandardError
        )
    }
}
