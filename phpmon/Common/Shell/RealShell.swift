//
//  RealShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import os
@preconcurrency import Dispatch

// Shell instances cross actors. Mutable configuration is protected by locks.
nonisolated class RealShell: ShellProtocol, @unchecked Sendable {
    init(binPath: String, preferredShell: String) {
        // Set variables that won't be updated
        self.binPath = binPath
        self.preferredShell = preferredShell

        // The PATH is resolved lazily on first access (see `PATH`): resolving it
        // spawns an interactive shell that can take seconds, and this initializer
        // runs on the main actor during `Container.bind()`. `AppDelegate.init`
        // warms the value up on the concurrent pool right after binding.
        self._PATH = OSAllocatedUnfairLock<String?>(initialState: nil)
        self._exports = OSAllocatedUnfairLock<[String: String]>(initialState: [:])
    }

    private(set) var binPath: String
    private(set) var preferredShell: String

    /**
     The launch path of the terminal in question that is used.
     On macOS, we use /bin/sh since it's pretty fast.
     */
    private(set) var launchPath: String = "/bin/sh"

    // MARK: - Thread-safe access; public accessor

    // Note: the `PATH` accessor (lazy resolution) lives in `RealShell+PATH.swift`.

    /**
     Exports are additional environment variables set by the user via the custom configuration.
     These are populated when the configuration file is being loaded.
     These are now set via via Process.environment to avoid security issues, like shell injection.
     */
    internal var exports: [String: String] {
        get { _exports.withLock { $0 } }
        set { _exports.withLock { $0 = newValue } }
    }

    // MARK: - Thread-safe access; internal values

    // `internal` (not private) because the `PATH` accessor lives in `RealShell+PATH.swift`.
    let _PATH: OSAllocatedUnfairLock<String?>
    private let _exports: OSAllocatedUnfairLock<[String: String]>

    // MARK: - Methods

    /**
     Create a process that will run the required shell with the appropriate arguments.
     This process still needs to be started, or one can attach output handlers.
     */
    private func getShellProcess(for command: String) -> Process {
        let completeCommand = "export PATH=\(binPath):$PATH && " + command

        let task = Process()
        task.launchPath = self.launchPath
        task.arguments = ["--noprofile", "-norc", "--login", "-c", completeCommand]

        // Set user-defined environment variables safely via Process API
        // instead of interpolating them into the shell command string.
        let currentExports = self.exports
        if !currentExports.isEmpty {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in currentExports {
                env[key] = value
            }
            task.environment = env
        }

        return task
    }

    /**
     Reads the entire output of a `Pipe` and returns it as a UTF‑8 string.
     Closes the pipe's file handler when done.
     */
    internal static func getStringOutput(from pipe: Pipe) -> String {
        let rawData = (try? pipe.fileHandleForReading.readToEnd()) ?? Data()
        let result = String(data: rawData, encoding: .utf8) ?? ""
        try? pipe.fileHandleForReading.close()

        return result
    }

    /// Drains both streams while the process runs, so neither pipe can fill up.
    internal static func getOutput(stdout: Pipe, stderr: Pipe) -> ShellOutput {
        let error = OSAllocatedUnfairLock(initialState: "")
        let readers = DispatchGroup()
        readers.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let text = getStringOutput(from: stderr)
            error.withLock { $0 = text }
            readers.leave()
        }
        let output = getStringOutput(from: stdout)
        readers.wait()
        return .out(output, error.withLock { $0 })
    }

    /**
    Verbose logging for when executing a shell command.
     */
    private func log(process: Process, stdOut: String, stdErr: String) {
        var args = process.arguments ?? []
        let last = "\"" + (args.popLast() ?? "") + "\""
        var log = """

            <~~~~~~~~~~~~~~~~~~~~~~~
            $ \(([self.launchPath] + args + [last]).joined(separator: " "))

            [OUT]:
            \(stdOut)
            """

        if !stdErr.isEmpty {
            log.append("""
                [ERR]:
                \(stdErr)
                """)
        }

        log.append("""
            ~~~~~~~~~~~~~~~~~~~~~~~~>

            """)

        Log.info(log)
    }

    // MARK: - Shellable Protocol

    @discardableResult
    func sync(_ command: String) -> ShellOutput {
        warnIfBlockingOnMainThread("shell.sync: \(command)")

        let process = getShellProcess(for: command)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        if ProcessInfo.processInfo.environment["SLOW_SHELL_MODE"] != nil {
            sleep(3)
        }

        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.launch()
        let output = Self.getOutput(stdout: outputPipe, stderr: errorPipe)
        process.waitUntilExit()

        if process.terminationReason == .uncaughtSignal {
            Log.err("The command `\(command)` likely crashed. Returning empty output.")
            return .out("", "")
        }

        if Log.shared.verbosity == .cli {
            log(process: process, stdOut: output.out, stdErr: output.err)
        }

        return output
    }

    @discardableResult
    func pipe(_ command: String) async -> ShellOutput {
        await pipe(command, timeout: .infinity)
    }

    @discardableResult
    func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput {
        do {
            let (process, output) = try await attach(command, didReceiveOutput: { _, _ in }, withTimeout: timeout)
            guard process.terminationReason != .uncaughtSignal else {
                Log.err("The command `\(command)` likely crashed. Returning empty output.")
                return .empty()
            }
            if Log.shared.verbosity == .cli {
                log(process: process, stdOut: output.out, stdErr: output.err)
            }
            return output
        } catch {
            Log.warn("Command failed: \(command): \(error)")
            return .empty()
        }
    }

    @discardableResult
    func attach(
        _ command: String,
        didReceiveOutput: @Sendable @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval = 5.0
    ) async throws -> (Process, ShellOutput) {
        if ProcessInfo.processInfo.environment["SLOW_SHELL_MODE"] != nil {
            Log.info("[SLOW SHELL] \(command)")
            await delay(seconds: 3.0)
        }

        let process = getShellProcess(for: command)
        let outputPipe = Pipe(), errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let queue = DispatchQueue(label: "com.nicoverbruggen.phpmon.attach_queue")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let state = OSAllocatedUnfairLock(initialState: ShellProcessState())

        return try await withCheckedThrowingContinuation { continuation in
            // Exit and EOF are separate events. A child can keep a pipe open after
            // the shell exits, so the timeout remains active until both streams close.
            let finish: @Sendable (Error?) -> Void = { error in
                let output = state.withLock { $0.finish(error: error) }
                guard let output else { return }

                timer.setEventHandler(handler: nil)
                timer.cancel()
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                process.terminationHandler = nil
                try? outputPipe.fileHandleForReading.close()
                try? errorPipe.fileHandleForReading.close()

                if let error {
                    if process.isRunning { process.terminate() }
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (process, output))
                }
            }

            let reader: @Sendable (ShellStream) -> (@Sendable (FileHandle) -> Void) = { stream in
                return { handle in
                    // The queue owns pipe reads and callback delivery. Completion
                    // cannot discard a chunk or deliver a callback after timeout.
                    queue.sync {
                        guard !state.withLock({ $0.finished }) else { return }
                        let data = handle.availableData
                        let text = state.withLock { state in
                            stream == .stdOut ? state.out.append(data) : state.err.append(data)
                        }
                        if data.isEmpty { handle.readabilityHandler = nil }
                        if !text.isEmpty { didReceiveOutput(text, stream) }
                        finish(nil)
                    }
                }
            }

            outputPipe.fileHandleForReading.readabilityHandler = reader(.stdOut)
            errorPipe.fileHandleForReading.readabilityHandler = reader(.stdErr)
            process.terminationHandler = { _ in
                queue.async {
                    state.withLock { $0.exited = true }
                    finish(nil)
                }
            }
            timer.setEventHandler { finish(ShellError.timedOut) }

            queue.async {
                do {
                    try process.run()
                    if timeout.isFinite {
                        timer.schedule(deadline: .now() + max(0, timeout))
                    }
                    timer.resume()
                } catch {
                    timer.resume()
                    finish(error)
                }
            }
        }
    }

    func reloadEnvPath() async {
        // Snapshot the main-actor resolved shell on main, then do the blocking PATH
        // lookup off-main with a plain `String` (no `App.shared` in the background closure).
        let resolved = await MainActor.run {
            App.shared.container.systemContext.shell.resolved
        }

        let path = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: RealShell.getPath(shell: resolved))
            }
        }

        self.PATH = path
    }
}

private nonisolated struct ShellProcessState: Sendable {
    var out = ShellOutputBuffer()
    var err = ShellOutputBuffer()
    var exited = false
    var finished = false

    mutating func finish(error: Error?) -> ShellOutput? {
        guard !finished else { return nil }
        guard error != nil || (exited && out.closed && err.closed) else { return nil }
        finished = true
        return .out(out.contents, err.contents)
    }
}

/// Decodes complete UTF-8 characters and retains a partial character for the next read.
private nonisolated struct ShellOutputBuffer: Sendable {
    var contents = ""
    var closed = false
    private var pending: [UInt8] = []

    mutating func append(_ data: Data) -> String {
        closed = data.isEmpty
        pending.append(contentsOf: data)
        var end = pending.count

        if !closed, let last = pending.indices.last {
            var start = last
            while start > 0 && pending[start] & 0xC0 == 0x80 && last - start < 3 {
                start -= 1
            }
            let length: Int
            switch pending[start] {
            case 0xC2...0xDF: length = 2
            case 0xE0...0xEF: length = 3
            case 0xF0...0xF4: length = 4
            default: length = 1
            }
            if end - start < length { end = start }
        }

        // Preserve valid output around malformed bytes by using replacement characters.
        // swiftlint:disable:next optional_data_string_conversion
        let text = String(decoding: pending.prefix(end), as: UTF8.self)
        pending.removeFirst(end)
        contents += text
        return text
    }
}
