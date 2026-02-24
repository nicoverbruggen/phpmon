//
//  TestableCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableCommand: CommandProtocol {
    init(commands: [String: String]) {
        self.commands = commands
    }

    var commands: [String: String]

    public func executeRaw(
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
