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

    init(expectations: [Input: BatchFakeShellOutput]) {
        self.expectations = expectations
    }

    var expectations: [Input: BatchFakeShellOutput] = [:]

    func quiet(_ command: String) async {
        return
    }

    func pipe(_ command: String) async -> ShellOutput {
        self.sync(command)
    }

    func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput) {
        return (Process(), self.sync(command))
    }

    func sync(_ command: String) -> ShellOutput {
        guard let expectation = expectations[command] else {
            return .err("Unexpected Command")
        }
        return ShellOutput(out: "", err: "")
    }
}

struct FakeShellOutput {
    let delay: TimeInterval
    let output: String
    let stream: ShellStream

    static func instant(_ output: String, _ stream: ShellStream = .stdOut) -> FakeShellOutput {
        return FakeShellOutput(delay: 0, output: output, stream: stream)
    }

    static func delayed(_ delay: TimeInterval, _ output: String, _ stream: ShellStream = .stdOut) -> FakeShellOutput {
        return FakeShellOutput(delay: delay, output: output, stream: stream)
    }
}

struct BatchFakeShellOutput {
    var items: [FakeShellOutput]

    /**
     Outputs the fake shell output as expected.
     */
    public func output(
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        ignoreDelay: Bool = false
    ) async -> ShellOutput {
        var output = ShellOutput(out: "", err: "")

        for item in items {
            if !ignoreDelay {
                let delay = UInt64(item.delay * 1_000_000_000)
                try! await Task.sleep(nanoseconds: delay)
            }

            if item.stream == .stdErr {
                output.err += item.output
            } else if item.stream == .stdOut {
                output.out += item.output
            }
        }

        return output
    }

    /**
     For testing purposes (and speed) we may omit the delay, regardless of its timespan.
     */
    public func outputInstantaneously(
        didReceiveOutput: @escaping (String, ShellStream) -> Void = { _, _ in }
    ) async -> ShellOutput {
        return await self.output(didReceiveOutput: didReceiveOutput, ignoreDelay: true)
    }
}
