//
//  TestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

public class TestableShell: ShellProtocol {
    var PATH: String {
        return "/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
    }

    init(expectations: [String: BatchFakeShellOutput]) {
        self.expectations = expectations
    }

    var expectations: [String: BatchFakeShellOutput] = [:]

    func sync(_ command: String) -> ShellOutput {
        // This assertion will only fire during test builds
        assert(expectations.keys.contains(command), "No response declared for command: \(command)")

        guard let expectation = expectations[command] else {
            return .err("No Expected Output")
        }

        return expectation.syncOutput()
    }

    func quiet(_ command: String) async {
        _ = try! await self.attach(command, didReceiveOutput: { _, _ in }, withTimeout: 60)
    }

    func pipe(_ command: String) async -> ShellOutput {
        let (_, output) = try! await self.attach(command, didReceiveOutput: { _, _ in }, withTimeout: 60)
        return output
    }

    func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput) {

        // Seriously slow down the shell's return rate in order to debug or identify async issues
        if ProcessInfo.processInfo.environment["SLOW_SHELL_MODE"] != nil {
            Log.info("[SLOW SHELL] \(command)")
            await delay(seconds: 3.0)
        }

        // This assertion will only fire during test builds
        assert(expectations.keys.contains(command), "No response declared for command: \(command)")

        guard let expectation = expectations[command] else {
            return (Process(), .err("No Expected Output"))
        }

        let output = await expectation.output(didReceiveOutput: { output, type in
            didReceiveOutput(output, type)
        }, ignoreDelay: isRunningTests)

        return (Process(), output)
    }
}

struct FakeShellOutput: Codable {
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

struct BatchFakeShellOutput: Codable {
    var items: [FakeShellOutput]

    static func with(_ items: [FakeShellOutput]) -> BatchFakeShellOutput {
        return BatchFakeShellOutput(items: items)
    }

    static func instant(_ output: String, _ stream: ShellStream = .stdOut) -> BatchFakeShellOutput {
        return BatchFakeShellOutput(items: [.instant(output, stream)])
    }

    static func delayed(
        _ delay: TimeInterval,
        _ output: String,
        _ stream: ShellStream = .stdOut
    ) -> BatchFakeShellOutput {
        return BatchFakeShellOutput(items: [.delayed(delay, output, stream)])
    }

    /**
     Outputs the fake shell output as expected.
     */
    public func output(
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        ignoreDelay: Bool = false
    ) async -> ShellOutput {
        let output = ShellOutput.empty()

        for item in items {
            if !ignoreDelay {
                await delay(seconds: item.delay)
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
     Outputs the fake shell output as expected, but does this synchronously.
     */
    public func syncOutput(
        ignoreDelay: Bool = false
    ) -> ShellOutput {
        let output = ShellOutput.empty()

        for item in items {
            if !ignoreDelay {
                sleep(UInt32(item.delay))
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
