//
//  TrackedTestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

final class TrackableTestableShell: TestableShell {
    private let commandTracker: CommandTracker

    init(expectations: [String: BatchFakeShellOutput], _ commandTracker: CommandTracker) {
        self.commandTracker = commandTracker
        super.init(expectations: expectations)
    }

    override func sync(_ command: String) -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return super.sync(command)
    }

    @discardableResult
    override func pipe(_ command: String) async -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return await super.pipe(command)
    }

    @discardableResult
    override func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return await super.pipe(command, timeout: timeout)
    }

    @discardableResult
    override func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput) {
        let trackingId = commandTracker.trackFromAnyThread(command)
        defer {
            commandTracker.completeFromAnyThread(trackingId)
        }
        return try await super.attach(
            command,
            didReceiveOutput: didReceiveOutput,
            withTimeout: timeout
        )
    }
}
