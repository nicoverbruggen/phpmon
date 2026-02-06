//
//  RealShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
@preconcurrency import Dispatch

class RealShell: ShellProtocol, @unchecked Sendable {
    init(binPath: String) {
        self.binPath = binPath
        self._PATH = RealShell.getPath()
        self._exports = [:]
    }

    private(set) var binPath: String

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
        get { shellQueue.sync { _PATH } }
        set { shellQueue.sync { _PATH = newValue } }
    }

    /**
     Exports are additional environment variables set by the user via the custom configuration.
     These are populated when the configuration file is being loaded.
     These are now set via via Process.environment to avoid security issues, like shell injection.
     */
    internal var exports: [String: String] {
        get { shellQueue.sync { _exports } }
        set { shellQueue.sync { _exports = newValue } }
    }

    // MARK: - Thread-safe access; internal values

    /** Thread-safe access to PATH and exports is ensured via this queue. */
    private let shellQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.shell_queue")
    private var _PATH: String
    private var _exports: [String: String]

    // MARK: - Methods

    /** Retrieves the user's PATH by opening an interactive shell and echoing $PATH. */
    private static func getPath() -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"

        // We need an interactive shell so the user's PATH is loaded in correctly
        task.arguments = ["--login", "-ilc", "echo $PATH"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let path = getStringOutput(from: pipe)
        return path.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
    private static func getStringOutput(from pipe: Pipe) -> String {
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

    // MARK: - Public API

    /**
     Set custom environment variables.
     These will be exported when a command is executed.
     */
    public func setCustomEnvironmentVariables(_ variables: [String: String]) {
        self.exports = variables
    }

    // MARK: - Shellable Protocol

    func sync(_ command: String) -> ShellOutput {
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
            var resumed = false

            let timeoutWorkItem = DispatchWorkItem {
                guard process.isRunning else { return }

                Log.warn("Command timed out after \(timeout)s: \(command)")
                process.terminationHandler = nil
                process.terminate()

                serialQueue.async {
                    if !resumed {
                        resumed = true
                        continuation.resume(returning: .out("", ""))
                    }
                }
            }

            serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

            process.terminationHandler = { [weak self] _ in
                timeoutWorkItem.cancel()

                serialQueue.async {
                    if resumed { return }

                    if process.terminationReason == .uncaughtSignal {
                        Log.err("The command `\(command)` likely crashed. Returning empty output.")
                        resumed = true
                        continuation.resume(returning: .out("", ""))
                        return
                    }

                    let stdOut = RealShell.getStringOutput(from: outputPipe)
                    let stdErr = RealShell.getStringOutput(from: errorPipe)

                    if Log.shared.verbosity == .cli {
                        self?.log(process: process, stdOut: stdOut, stdErr: stdErr)
                    }

                    resumed = true
                    continuation.resume(returning: .out(stdOut, stdErr))
                }
            }

            process.launch()
        }
    }

    func quiet(_ command: String) async {
        _ = await self.pipe(command)
    }

    func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval = 5.0
    ) async throws -> (Process, ShellOutput) {
        let process = getShellProcess(for: command)
        let outputPipe = Pipe(), errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let output = ShellOutput.empty()

        // Only access `resumed`, `output` from serialQueue to ensure thread safety
        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.attach_queue")

        return try await withCheckedThrowingContinuation({ continuation in
            // Guard against resuming the continuation twice (race between timeout and termination)
            var resumed = false

            // Use GCD; we're already using a serial queue so legacy concurrency approach is okay
            let timeoutTaskTermination = DispatchWorkItem {
                guard process.isRunning else { return }

                process.terminationHandler = nil
                process.terminate()

                if !resumed {
                    resumed = true
                    continuation.resume(throwing: ShellError.timedOut)
                }
            }

            // Let's make sure that once our timeout occurs, our process is terminated
            serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutTaskTermination)

            // Set up background reading for stdout
            outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                    serialQueue.async {
                        output.out += string
                        didReceiveOutput(string, .stdOut)
                    }
                }
            }

            // Set up background reading for stderr
            errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                    serialQueue.async {
                        output.err += string
                        didReceiveOutput(string, .stdErr)
                    }
                }
            }

            process.terminationHandler = { process in
                serialQueue.async {
                    timeoutTaskTermination.cancel()

                    // Check if already resumed (timeout fired first)
                    if resumed { return }

                    // Clean up readability handlers
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    // Read any remaining data
                    let remainingOut = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let remainingErr = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    if !remainingOut.isEmpty, let string = String(data: remainingOut, encoding: .utf8) {
                        output.out += string
                        didReceiveOutput(string, .stdOut)
                    }

                    if !remainingErr.isEmpty, let string = String(data: remainingErr, encoding: .utf8) {
                        output.err += string
                        didReceiveOutput(string, .stdErr)
                    }

                    resumed = true
                    continuation.resume(returning: (process, output))
                }
            }

            process.launch()
        })
    }

    func reloadEnvPath() {
        // Instead of replacing the entire shell instance, we simply re-fetch the PATH
        self.PATH = RealShell.getPath()
    }
}
