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

    var exports: [String: String] {
        get { shell.exports }
        set { shell.exports = newValue }
    }

    func reloadEnvPath() async {
        await shell.reloadEnvPath()
    }
}
