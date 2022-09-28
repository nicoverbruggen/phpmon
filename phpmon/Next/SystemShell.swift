//
//  SystemShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class SystemShell: Shellable {
    /**
     The launch path of the terminal in question that is used.
     On macOS, we use /bin/sh since it's pretty fast.
     */
    private(set) var launchPath: String = "/bin/sh"

    /**
     For some commands, we need to know what's in the user's PATH.
     The entire PATH is retrieved here, so we can set the PATH in our own terminal as necessary.
     */
    private(set) var PATH: String = { return SystemShell.getPath() }()

    /**
     Exports are additional environment variables set by the user via the custom configuration.
     These are populated when the configuration file is being loaded.
     */
    private(set) var exports: String = ""

    /** Retrieves the user's PATH by opening an interactive shell and echoing $PATH. */
    private static func getPath() -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"

        // We need an interactive shell so the user's PATH is loaded in correctly
        task.arguments = ["--login", "-ilc", "echo $PATH"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        return String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: String.Encoding.utf8
        ) ?? ""
    }

    /**
     Create a process that will run the required shell with the appropriate arguments.
     This process still needs to be started, or one can attach output handlers.
     */
    private func getShellProcess(for command: String) -> Process {
        var completeCommand = ""

        // Basic export (PATH)
        completeCommand += "export PATH=\(Paths.binPath):$PATH && "

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
        let task = getShellProcess(for: command)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        task.waitUntilExit()

        let stdOut = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!

        let stdErr = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!

        if stdErr.lengthOfBytes(using: .utf8) > 0 {
            return ShellOutput(output: stdErr, isError: true)
        }

        return ShellOutput(output: stdOut, isError: false)
    }

    func pipe(_ command: String) async -> ShellOutput {
        return sync(command)
    }

    func quiet(_ command: String) async {
        _ = await self.pipe(command)
    }

    func attach(
        _ command: String,
        didReceiveOutput: @escaping (ShellOutput) -> Void,
        withTimeout timeout: TimeInterval = 5.0
    ) async throws -> ShellOutput {
        let task = getShellProcess(for: command)

        var allOut: String = ""
        var allErr: String = ""

        task.listen { stdOut in
            allOut += stdOut; didReceiveOutput(.out(stdOut))
        } didReceiveStandardErrorData: { stdErr in
            allErr += stdErr; didReceiveOutput(.err(stdErr))
        }

        return try await withCheckedThrowingContinuation({ continuation in
            var timer: Timer?

            task.terminationHandler = { process in
                process.haltListening()

                timer?.invalidate()

                if !allErr.isEmpty {
                    return continuation.resume(returning: .err(allErr))
                }

                return continuation.resume(returning: .out(allOut))
            }

            timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                task.terminationHandler = nil
                task.terminate()
                return continuation.resume(throwing: ShellError.timedOut)
            }

            task.launch()
            task.waitUntilExit()
        })
    }
}
