//
//  TestableCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import os

// Output overrides can change during a UI test while probes run off-main. The lock
// protects those updates and reads. The tracking subclass requires unchecked Sendable.
nonisolated class TestableCommand: CommandProtocol, @unchecked Sendable {
    init(commands: [String: String]) {
        self.state = OSAllocatedUnfairLock(initialState: commands)
    }

    private let state: OSAllocatedUnfairLock<[String: String]>

    var commands: [String: String] { state.withLock { $0 } }

    func updateOutputs(_ outputs: [String: String]) {
        state.withLock { $0.merge(outputs) { _, new in new } }
    }

    public func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool,
        withStandardError: Bool
    ) -> String {
        let concatenatedCommand = "\(path) \(arguments.joined(separator: " "))"
        let output = state.withLock { $0[concatenatedCommand] }
        assert(output != nil, "Command `\(concatenatedCommand)` not found")
        return output!
    }
}
