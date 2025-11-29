//
//  RealShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class RealShell: ShellProtocol {
    var container: Container

    init(container: Container) {
        self.container = container
        self.PATH = RealShell.getPath()
    }

    /**
     The launch path of the terminal in question that is used.
     On macOS, we use /bin/sh since it's pretty fast.
     */
    private(set) var launchPath: String = "/bin/sh"

    /**
     For some commands, we need to know what's in the user's PATH.
     The entire PATH is retrieved here, so we can set the PATH in our own terminal as necessary.
     */
    private(set) var PATH: String

    /**
     Exports are additional environment variables set by the user via the custom configuration.
     These are populated when the configuration file is being loaded.
     */
    var exports: String = ""

    /** Retrieves the user's PATH by opening an interactive shell and echoing $PATH. */
    private static func getPath() -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"

        // We need an interactive shell so the user's PATH is loaded in correctly
        task.arguments = ["--login", "-ilc", "echo $PATH"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let path = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: String.Encoding.utf8
        ) ?? ""

        try? pipe.fileHandleForReading.close()

        return path
    }

    /**
     Create a process that will run the required shell with the appropriate arguments.
     This process still needs to be started, or one can attach output handlers.
     */
    private func getShellProcess(for command: String) -> Process {
        var completeCommand = ""

        // Basic export (PATH)
        completeCommand += "export PATH=\(container.paths.binPath):$PATH && "

        // Put additional exports (as defined by the user) in between
        if !self.exports.isEmpty {
            completeCommand += "\(self.exports) && "
        }

        completeCommand += command

        let task = Process()
        task.launchPath = self.launchPath
        task.arguments = ["--noprofile", "-norc", "--login", "-c", completeCommand]

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

    // MARK: - Public API

    /**
     Set custom environment variables.
     These will be exported when a command is executed.
     */
    public func setCustomEnvironmentVariables(_ variables: [String: String]) {
        self.exports = variables.map { (key, value) in
            return "export \(key)=\(value)"
        }.joined(separator: "&&")
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
        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.shell_output")

        return try await withCheckedThrowingContinuation({ continuation in
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: timeout.nanoseconds)
                // Only terminate if the process is still running
                if process.isRunning {
                    process.terminationHandler = nil
                    process.terminate()
                    continuation.resume(throwing: ShellError.timedOut)
                }
            }

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
                timeoutTask.cancel()

                // Clean up readability handlers
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                // Read any remaining data
                let remainingOut = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingErr = errorPipe.fileHandleForReading.readDataToEndOfFile()

                serialQueue.async {
                    if !remainingOut.isEmpty, let string = String(data: remainingOut, encoding: .utf8) {
                        output.out += string
                        didReceiveOutput(string, .stdOut)
                    }

                    if !remainingErr.isEmpty, let string = String(data: remainingErr, encoding: .utf8) {
                        output.err += string
                        didReceiveOutput(string, .stdErr)
                    }

                    if !output.err.isEmpty {
                        continuation.resume(returning: (process, .err(output.err)))
                    } else {
                        continuation.resume(returning: (process, .out(output.out)))
                    }
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
