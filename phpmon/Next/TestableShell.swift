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
        didReceiveOutput: @escaping (ShellOutput) -> Void,
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

// TODO: Test env shell output should be modeled differently
// So the possible outcome is either:
// 1. Immediate with almost zero delay `.instant("string")`
// 2. Delayed but then all at once: `.delay(300, "string")`
// 3. A stream of data spread over multiple seconds: `.multiple([.delay(300, "hello"), .delay(300, "bye")])`

struct FakeShellOutput {
    let delay: TimeInterval
    let output: ShellOutput

    static func instant(_ stdOut: String, _ stdErr: String? = nil) -> FakeShellOutput {
        return FakeShellOutput(delay: 0, output: ShellOutput(out: stdOut, err: stdErr ?? ""))
    }

    static func delayed(_ delay: TimeInterval, _ stdOut: String, _ stdErr: String? = nil) -> FakeShellOutput {
        return FakeShellOutput(delay: delay, output: ShellOutput(out: stdOut, err: stdErr ?? ""))
    }
}

struct BatchFakeShellOutput {
    var items: [FakeShellOutput]

    /**
     Outputs the fake shell output as expected.
     */
    public func output(
        didReceiveOutput: @escaping (ShellOutput) -> Void,
        ignoreDelay: Bool = false
    ) async -> ShellOutput {
        var allOut: String = ""
        var allErr: String = ""

        Task {
            self.items.forEach { fakeShellOutput in
                let delay = UInt64(fakeShellOutput.delay * 1_000_000_000)
                try await Task.sleep(nanoseconds: delay)

                allOut += fakeShellOutput.output.out

                if fakeShellOutput.output.hasError {
                    allErr += fakeShellOutput.output.err
                }
            }
        }

        return ShellOutput(
            out: allOut,
            err: allErr
        )
    }

    /**
     For testing purposes (and speed) we may omit the delay, regardless of its timespan.
     */
    public func outputInstantaneously(
        didReceiveOutput: @escaping (ShellOutput) -> Void
    ) -> ShellOutput {
        self.output(didReceiveOutput: didReceiveOutput, ignoreDelay: true)
    }
}
