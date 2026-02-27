//
//  TestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

public class TestableShell: ShellProtocol {
    var PATH: String {
        return "/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
    }

    init(expectations: [String: BatchFakeShellOutput], filesystem: TestableFileSystem? = nil) {
        self.expectations = expectations
        self.filesystem = filesystem
    }

    var expectations: [String: BatchFakeShellOutput] = [:]
    var filesystem: TestableFileSystem?

    @discardableResult
    func sync(_ command: String) -> ShellOutput {
        // This assertion will only fire during test builds
        assert(expectations.keys.contains(command), "No response declared for command: \(command)")

        guard let expectation = expectations[command] else {
            return .err("No Expected Output")
        }

        let output = expectation.syncOutput()
        applyTransactions(for: expectation)
        return output
    }

    @discardableResult
    func pipe(_ command: String) async -> ShellOutput {
        await pipe(command, timeout: 60)
    }

    @discardableResult
    func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput {
        let (_, output) = try! await self.attach(command, didReceiveOutput: { _, _ in }, withTimeout: timeout)
        return output
    }

    @discardableResult
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

        applyTransactions(for: expectation)
        return (Process(), output)
    }

    func reloadEnvPath() {
        // does nothing
    }

    private func applyTransactions(for expectation: BatchFakeShellOutput) {
        if !expectation.transactions.isEmpty {
            assert(filesystem != nil, "Transactions require a filesystem")
        }

        guard let filesystem else {
            return
        }

        expectation.transactions.forEach { transaction in
            transaction.apply(to: filesystem, shell: self)
        }
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
    var transactions: [FakeShellTransaction] = []

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

            didReceiveOutput(item.output, item.stream)

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
                Thread.sleep(forTimeInterval: item.delay)
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

struct FakeShellTransaction: Codable {
    enum TransactionType: String, Codable {
        case createSymlink
        case writeFile
        case remove
        case move
        case createDirectory
        case makeExecutable
        case setShellOutput
    }

    var type: TransactionType
    var path: String?
    var destination: String?
    var content: String?
    var overwrite: Bool?
    var from: String?
    var to: String?
    var command: String?
    var output: BatchFakeShellOutput?

    static func createSymlink(path: String, destination: String) -> FakeShellTransaction {
        FakeShellTransaction(type: .createSymlink, path: path, destination: destination)
    }

    static func symlink(_ path: String, to destination: String) -> FakeShellTransaction {
        createSymlink(path: path, destination: destination)
    }

    static func writeFile(path: String, content: String, overwrite: Bool) -> FakeShellTransaction {
        FakeShellTransaction(type: .writeFile, path: path, content: content, overwrite: overwrite)
    }

    static func file(_ path: String, content: String, overwrite: Bool) -> FakeShellTransaction {
        writeFile(path: path, content: content, overwrite: overwrite)
    }

    static func remove(path: String) -> FakeShellTransaction {
        FakeShellTransaction(type: .remove, path: path)
    }

    static func remove(_ path: String) -> FakeShellTransaction {
        remove(path: path)
    }

    static func move(from: String, to: String) -> FakeShellTransaction {
        FakeShellTransaction(type: .move, from: from, to: to)
    }

    static func move(_ from: String, to: String) -> FakeShellTransaction {
        move(from: from, to: to)
    }

    static func createDirectory(path: String) -> FakeShellTransaction {
        FakeShellTransaction(type: .createDirectory, path: path)
    }

    static func directory(_ path: String) -> FakeShellTransaction {
        createDirectory(path: path)
    }

    static func makeExecutable(path: String) -> FakeShellTransaction {
        FakeShellTransaction(type: .makeExecutable, path: path)
    }

    static func executable(_ path: String) -> FakeShellTransaction {
        makeExecutable(path: path)
    }

    static func setShellOutput(command: String, output: BatchFakeShellOutput) -> FakeShellTransaction {
        FakeShellTransaction(type: .setShellOutput, command: command, output: output)
    }

    static func shellOutput(_ command: String, output: BatchFakeShellOutput) -> FakeShellTransaction {
        setShellOutput(command: command, output: output)
    }

    func apply(to filesystem: TestableFileSystem, shell: TestableShell) {
        switch type {
        case .createSymlink:
            assert(path != nil && destination != nil, "createSymlink requires path and destination")
            filesystem.createSymlink(path!, destination: destination!)
        case .writeFile:
            assert(path != nil && content != nil && overwrite != nil, "writeFile requires path, content, overwrite")
            try? filesystem.writeFile(path!, content: content!, overwrite: overwrite!)
        case .remove:
            assert(path != nil, "remove requires path")
            try? filesystem.remove(path!)
        case .move:
            assert(from != nil && to != nil, "move requires from and to")
            try? filesystem.move(from: from!, to: to!)
        case .createDirectory:
            assert(path != nil, "createDirectory requires path")
            try? filesystem.createDirectory(path!, withIntermediateDirectories: true)
        case .makeExecutable:
            assert(path != nil, "makeExecutable requires path")
            try? filesystem.makeExecutable(path!)
        case .setShellOutput:
            assert(command != nil && output != nil, "setShellOutput requires command and output")
            shell.expectations[command!] = output!
        }
    }
}
