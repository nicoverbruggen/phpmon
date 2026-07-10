//
//  RealShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
@preconcurrency import Dispatch

// Nonisolated so blocking subprocess I/O stays off the main actor. Its mutable state
// (`_PATH`, `_exports`) is `Locked`-guarded, hence `@unchecked Sendable`.
nonisolated class RealShell: ShellProtocol, @unchecked Sendable {
    init(binPath: String, preferredShell: String) {
        // Set variables that won't be updated
        self.binPath = binPath
        self.preferredShell = preferredShell

        // The PATH is resolved lazily on first access (see `PATH`): resolving it
        // spawns an interactive shell that can take seconds, and this initializer
        // runs on the main actor during `Container.bind()`. `AppDelegate.init`
        // warms the value up on the concurrent pool right after binding.
        self._PATH = Locked<String?>(nil)
        self._exports = Locked<[String: String]>([:])
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
        get { _exports.value }
        set { _exports.value = newValue }
    }

    // MARK: - Thread-safe access; internal values

    // `internal` (not private) because the `PATH` accessor lives in `RealShell+PATH.swift`.
    let _PATH: Locked<String?>
    private let _exports: Locked<[String: String]>

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
        // 1. Read all data (safely).
        let rawData = (try? pipe.fileHandleForReading.readToEnd()) ?? Data()

        // 2. Convert to string (safely).
        let result = String(data: rawData, encoding: .utf8) ?? ""

        // 3. Close the handle quietly.
        try? pipe.fileHandleForReading.close()

        return result
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
        process.waitUntilExit()

        if process.terminationReason == .uncaughtSignal {
            Log.err("The command `\(command)` likely crashed. Returning empty output.")
            return .out("", "")
        }

        let stdOut = RealShell.getStringOutput(from: outputPipe)
        let stdErr = RealShell.getStringOutput(from: errorPipe)

        if Log.shared.verbosity == .cli {
            log(process: process, stdOut: stdOut, stdErr: stdErr)
        }

        return .out(stdOut, stdErr)
    }

    @discardableResult
    func pipe(_ command: String) async -> ShellOutput {
        let process = getShellProcess(for: command)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        if ProcessInfo.processInfo.environment["SLOW_SHELL_MODE"] != nil {
            Log.info("[SLOW SHELL] \(command)")
            await delay(seconds: 3.0)
        }

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return await withCheckedContinuation { continuation in
            process.terminationHandler = { [weak self] _ in
                if process.terminationReason == .uncaughtSignal {
                    Log.err("The command `\(command)` likely crashed. Returning empty output.")
                    return continuation.resume(returning: .out("", ""))
                }

                let stdOut = RealShell.getStringOutput(from: outputPipe)
                let stdErr = RealShell.getStringOutput(from: errorPipe)

                if Log.shared.verbosity == .cli {
                    self?.log(process: process, stdOut: stdOut, stdErr: stdErr)
                }

                return continuation.resume(returning: .out(stdOut, stdErr))
            }

            process.launch()
        }
    }

    @discardableResult
    func pipe(_ command: String, timeout: TimeInterval) async -> ShellOutput {
        let process = getShellProcess(for: command)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        if ProcessInfo.processInfo.environment["SLOW_SHELL_MODE"] != nil {
            Log.info("[SLOW SHELL] \(command)")
            await delay(seconds: 3.0)
        }

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.pipe_timeout_queue")

        return await withCheckedContinuation { continuation in
            // Once-only "resume" guard, mutated from `@Sendable` serial-queue closures;
            // `Locked` keeps it data-race free while preserving "resume exactly once".
            let resumed = Locked<Bool>(false)

            let timeoutWorkItem = DispatchWorkItem {
                guard process.isRunning else { return }

                Log.warn("Command timed out after \(timeout)s: \(command)")
                process.terminationHandler = nil
                process.terminate()

                serialQueue.async {
                    if !resumed.value {
                        resumed.value = true
                        continuation.resume(returning: .out("", ""))
                    }
                }
            }

            serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

            process.terminationHandler = { [weak self] _ in
                timeoutWorkItem.cancel()

                // Immutable, Sendable snapshot so the concurrent queue closure captures a
                // `let` rather than the mutable optional `self` binding.
                let shell = self
                serialQueue.async {
                    if resumed.value { return }

                    if process.terminationReason == .uncaughtSignal {
                        Log.err("The command `\(command)` likely crashed. Returning empty output.")
                        resumed.value = true
                        continuation.resume(returning: .out("", ""))
                        return
                    }

                    let stdOut = RealShell.getStringOutput(from: outputPipe)
                    let stdErr = RealShell.getStringOutput(from: errorPipe)

                    if Log.shared.verbosity == .cli {
                        shell?.log(process: process, stdOut: stdOut, stdErr: stdErr)
                    }

                    resumed.value = true
                    continuation.resume(returning: .out(stdOut, stdErr))
                }
            }

            process.launch()
        }
    }

    @discardableResult
    func attach(
        _ command: String,
        didReceiveOutput: @Sendable @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval = 5.0
    ) async throws -> (Process, ShellOutput) {
        let process = getShellProcess(for: command)
        let outputPipe = Pipe(), errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Accumulate into `Locked` buffers (safe across the `@Sendable` serial-queue
        // closures); the immutable `ShellOutput` is built once at `continuation.resume`.
        let outBuffer = Locked<String>("")
        let errBuffer = Locked<String>("")

        // All mutable state AND all pipe reads are confined to this queue.
        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.attach_queue")

        return try await withCheckedThrowingContinuation({ continuation in
            // `Locked` guard: safe mutation from the `@Sendable` timeout/termination closures.
            let finished = Locked<Bool>(false)

            // Runs on `serialQueue`: the drain sees all data the handlers didn't consume.
            let finishSuccess: @Sendable () -> Void = {
                if finished.value { return }
                finished.value = true

                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                let remainingOut = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingErr = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if !remainingOut.isEmpty, let string = String(data: remainingOut, encoding: .utf8) {
                    outBuffer.withLock { $0 += string }
                    didReceiveOutput(string, .stdOut)
                }

                if !remainingErr.isEmpty, let string = String(data: remainingErr, encoding: .utf8) {
                    errBuffer.withLock { $0 += string }
                    didReceiveOutput(string, .stdErr)
                }

                let output = ShellOutput(out: outBuffer.value, err: errBuffer.value)
                continuation.resume(returning: (process, output))
            }

            let finishTimeout: @Sendable () -> Void = {
                if finished.value { return }
                finished.value = true

                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                process.terminationHandler = nil
                if process.isRunning {
                    process.terminate()
                }

                continuation.resume(throwing: ShellError.timedOut)
            }

            let timeoutTaskTermination = DispatchWorkItem {
                serialQueue.async {
                    finishTimeout()
                }
            }

            serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutTaskTermination)

            // Background reading for stdout/stderr. Consuming `availableData` inside
            // the `sync` block makes "check finished → consume → append" one critical
            // section: a chunk consumed just before termination flips `finished` would
            // otherwise be dropped by the guard, yet the `finishSuccess` drain can
            // never re-read consumed data. `availableData` won't block: the handler
            // only fires when the pipe is readable, and the drain runs behind this queue.
            let makeReadabilityHandler: @Sendable (Locked<String>, ShellStream)
                -> (@Sendable (FileHandle) -> Void) = { buffer, stream in
                return { fileHandle in
                    serialQueue.sync {
                        if finished.value { return }
                        let data = fileHandle.availableData
                        if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                            buffer.withLock { $0 += string }
                            didReceiveOutput(string, stream)
                        }
                    }
                }
            }

            outputPipe.fileHandleForReading.readabilityHandler = makeReadabilityHandler(outBuffer, .stdOut)
            errorPipe.fileHandleForReading.readabilityHandler = makeReadabilityHandler(errBuffer, .stdErr)

            process.terminationHandler = { _ in
                serialQueue.async {
                    timeoutTaskTermination.cancel()
                    finishSuccess()
                }
            }

            process.launch()
        })
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
