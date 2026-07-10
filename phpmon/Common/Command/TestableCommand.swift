//
//  TestableCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// `nonisolated` + `@unchecked Sendable`: a test double whose only state (`commands`) is an
// immutable `let` set at construction, so it is genuinely data-race-free; `@unchecked` is
// required only because this class is non-final (the `TrackableTestableCommand` subclass
// exists to wire up command tracking), and Swift cannot auto-synthesize `Sendable` for a
// non-final class.
nonisolated class TestableCommand: CommandProtocol, @unchecked Sendable {
    init(commands: [String: String]) {
        self.commands = commands
    }

    let commands: [String: String]

    public func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool,
        withStandardError: Bool
    ) -> String {
        let concatenatedCommand = "\(path) \(arguments.joined(separator: " "))"
        assert(commands.keys.contains(concatenatedCommand), "Command `\(concatenatedCommand)` not found")
        return self.commands[concatenatedCommand]!
    }
}
