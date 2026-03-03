//
//  TrackedShell.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

final class TrackedShell: ShellProtocol {
    private let shell: ShellProtocol
    private let commandTracker: CommandTracker

    init(shell: ShellProtocol, commandTracker: CommandTracker) {
        self.shell = shell
        self.commandTracker = commandTracker
    }

    var PATH: String {
        shell.PATH
    }

    func sync(_ command: String) -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return shell.sync(command)
    }

    @discardableResult
    func pipe(_ command: String) async -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return await shell.pipe(command)
    }

    @discardableResult
    func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return await shell.pipe(command, timeout: timeout)
    }

    @discardableResult
    func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput) {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return try await shell.attach(command, didReceiveOutput: didReceiveOutput, withTimeout: timeout)
    }

    // MARK: - Custom exports
    // (probably should be part of the protocol?)

    var customExports: [String: String] {
        if let shell = self.shell as? RealShell {
            return shell.exports
        } else if let shell = self.shell as? TestableShell {
            return shell.exports
        } else {
            assertionFailure("This shell does not support retrieving custom exports.")
            return [:]
        }
    }

    func setCustomExports(_ variables: [String: String]) {
        if let shell = self.shell as? RealShell {
            shell.exports = variables
        } else if let shell = self.shell as? TestableShell {
            shell.exports = variables
        } else {
            assertionFailure("Custom exports were set in `config.json`, but not applied because the shell does not support it.")
        }
    }

    func reloadEnvPath() {
        shell.reloadEnvPath()
    }
}
