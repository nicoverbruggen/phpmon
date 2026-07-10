//
//  RealShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
@preconcurrency import Dispatch

// Nonisolated so it stays off the main actor once the app moves to main-actor-by-default:
// this runs subprocesses to completion and must never block the UI thread. Its mutable
// state (`_PATH`, `_exports`) is `Locked`-guarded, hence `@unchecked Sendable`.
nonisolated class RealShell: ShellProtocol, @unchecked Sendable {
    init(binPath: String, preferredShell: String) {
        // Set variables that won't be updated
        self.binPath = binPath
        self.preferredShell = preferredShell

        // Retrieve the PATH
        let PATH = RealShell.getPath(shell: preferredShell)

        // Set thread-safe variables
        self._PATH = Locked<String>(PATH)
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

    /**
     For some commands, we need to know what's in the user's PATH.
     The entire PATH is retrieved here, so we can set the PATH in our own terminal as necessary.
     */
    internal var PATH: String {
        get { _PATH.value }
        set { _PATH.value = newValue }
    }

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

    private let _PATH: Locked<String>
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
            // The once-only "resume" guard is mutated from `@Sendable` serial-queue
            // closures; a plain captured `var` would be a data-race warning. `Locked`
            // makes the mutation compiler-safe. (All access still happens on the serial
            // queue, so the invariant "resume exactly once" is preserved.)
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

        // Accumulate output in thread-safe buffers instead of a mutable `ShellOutput`.
        // `ShellOutput` is now an immutable `Sendable` value; we build the final one
        // once, at `continuation.resume`. `Locked` keeps these captures compiler-safe
        // across the `@Sendable` serial-queue closures. (All access still happens on
        // the serial queue below, so ordering is preserved.)
        let outBuffer = Locked<String>("")
        let errBuffer = Locked<String>("")

        // Only access mutable state from this queue.
        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.attach_queue")

        return try await withCheckedThrowingContinuation({ continuation in
            // Guard against all races: timeout, termination and late readability callbacks.
            // `Locked` so mutation from the `@Sendable` serial-queue closures is safe.
            let finished = Locked<Bool>(false)

            let finishSuccess: @Sendable () -> Void = {
                if finished.value { return }
                finished.value = true

                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                let remainingOut = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingErr = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if !remainingOut.isEmpty, let string = String(data: remainingOut, encoding: .utf8) {
                    outBuffer.value += string
                    didReceiveOutput(string, .stdOut)
                }

                if !remainingErr.isEmpty, let string = String(data: remainingErr, encoding: .utf8) {
                    errBuffer.value += string
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

            // Set up background reading for stdout
            outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                    serialQueue.async {
                        if finished.value { return }
                        outBuffer.value += string
                        didReceiveOutput(string, .stdOut)
                    }
                }
            }

            // Set up background reading for stderr
            errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                    serialQueue.async {
                        if finished.value { return }
                        errBuffer.value += string
                        didReceiveOutput(string, .stdErr)
                    }
                }
            }

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
        // Read the main-actor-isolated resolved shell on the main actor, then hand the
        // plain `String` off to a background queue for the (blocking) PATH lookup. This
        // keeps `App.shared` off the `@Sendable` background closure while preserving the
        // original behavior of resolving the PATH off the main thread.
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
