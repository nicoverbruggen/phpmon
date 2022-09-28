//
//  TestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public class TestableShell: Shellable {
    public typealias Input = String

    init(expectations: [Input: OutputsToShell]) {
        self.expectations = expectations
    }

    var expectations: [Input: OutputsToShell] = [:]

    func quiet(_ command: String) async {
        return
    }

    func pipe(_ command: String) async -> ShellOutput {
        self.sync(command)
    }

    func attach(
        _ command: String,
        didReceiveOutput: @escaping (ShellOutput) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> ShellOutput {
        self.sync(command)
    }

    func sync(_ command: String) -> ShellOutput {
        guard let expectation = expectations[command] else {
            return .err("Unexpected Command")
        }

        let output = expectation.getOutputAsString()
        return expectation.outputsToError() ? .err(output) : .out(output)
    }
}

protocol OutputsToShell {
    func getOutputAsString() -> String
    func getDuration() -> Int
    func outputsToError() -> Bool
}

struct FakeTerminalOutput: OutputsToShell {
    var output: String
    var duration: Int
    var isError: Bool

    func getOutputAsString() -> String {
        return output
    }

    func getDuration() -> Int {
        return duration
    }

    func outputsToError() -> Bool {
        return isError
    }
}

extension String: OutputsToShell {
    func getOutputAsString() -> String {
        return self
    }

    func getDuration() -> Int {
        return 100
    }

    func outputsToError() -> Bool {
        return false
    }
}
