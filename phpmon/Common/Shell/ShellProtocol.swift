//
//  ShellProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// `Sendable`: shell handles are handed to the off-main, nonisolated `BrewCommand` family
// and captured in `@Sendable` output callbacks, so `any ShellProtocol` must cross isolation
// boundaries. All conformers are either truly immutable (`TrackedShell`) or guard their
// state (`RealShell`/`TestableShell`).
nonisolated protocol ShellProtocol: AnyObject, Sendable {
    /**
     The PATH for the current shell.
     */
    var PATH: String { get }

    /**
     Exports are additional environment variables set by the user via the custom configuration.
     These are populated when the configuration file is being loaded.
     */
    var exports: [String: String] { get set }

    /**
     Run a command synchronously. Use with caution!

     Common usage:
     ```
     let output = Shell.sync("php -v")
     ```

     @return The shell output. If the command times out, returns empty output.
     */
    @discardableResult
    func sync(_ command: String) -> ShellOutput

    /**
     Run a command asynchronously.

     Common usage:
     ```
    let output = await Shell.pipe("php -v")
     ```

     @return The shell output. If the command times out, returns empty output.
     */
    @discardableResult
    func pipe(_ command: String) async -> ShellOutput

    /**
     Run a command asynchronously with a timeout.
     Returns the most relevant output (prefers error output if it exists).

     - Parameter command: The command to execute.
     - Parameter timeout: Timeout in seconds. If the command exceeds this, it is terminated.

     @return The shell output. If the command times out, returns empty output.
     */
    @discardableResult
    func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput

    /**
     Runs a command asynchronously, and fires closure with `stdout` or `stderr` data as it comes in.

     You can specify how long this task should run.
     The process will always be terminated after the specified time interval.
     (Whether it is complete or not.)

     Unlike `sync`, `pipe` and `quiet`, you can capture both `stdout` and `stderr` with this mechanism.

     @return A tuple, containing the `Process` and `ShellOutput` objects.
     */
    @discardableResult
    func attach(
        _ command: String,
        didReceiveOutput: @Sendable @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput)

    /**
     Reloads the PATH.
     */
    func reloadEnvPath() async
}

// `nonisolated` + `Sendable`: this value is passed through `@Sendable` shell
// callbacks and returned across isolation boundaries (from the nonisolated shell
// into main-actor callers), so it must not pick up main-actor isolation.
nonisolated enum ShellStream: Codable, Sendable {
    case stdOut, stdErr, stdIn
}

// A `Sendable` value type: it is built off the main actor (inside shell
// callbacks/continuations) and handed back to main-actor callers, so it crosses
// isolation boundaries. Immutable `let` storage makes it safely `Sendable` without
// `@unchecked`. `nonisolated` keeps its members callable from any isolation.
nonisolated struct ShellOutput: Sendable {
    let out: String
    let err: String

    var hasError: Bool {
        return err.lengthOfBytes(using: .utf8) > 0
    }

    init(out: String, err: String) {
        self.out = out
        self.err = err
    }

    static func empty() -> ShellOutput {
        return ShellOutput(out: "", err: "")
    }

    static func out(_ out: String?, _ err: String? = nil) -> ShellOutput {
        return ShellOutput(out: out ?? "", err: err ?? "")
    }

    static func err(_ err: String?) -> ShellOutput {
        return ShellOutput(out: "", err: err ?? "")
    }
}

// `nonisolated` + `Sendable`: thrown across isolation boundaries (from the
// nonisolated shell into main-actor callers), so it must stay isolation-free.
nonisolated enum ShellError: Error, Sendable {
    case timedOut
}
