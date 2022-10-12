//
//  TestableCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableCommand: CommandProtocol {
    init(commands: [String: String]) {
        self.commands = commands
    }

    var commands: [String: String]

    func execute(path: String, arguments: [String]) -> String {
        self.execute(path: path, arguments: arguments, trimNewlines: false)
    }

    public func execute(path: String, arguments: [String], trimNewlines: Bool) -> String {
        let concatenatedCommand = "\(path) \(arguments.joined(separator: " "))"
        assert(commands.keys.contains(concatenatedCommand), "The expected command (\(concatenatedCommand)) was not found")
        return self.commands[concatenatedCommand]!
    }
}
