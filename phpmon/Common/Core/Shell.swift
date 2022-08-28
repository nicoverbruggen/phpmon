//
//  Shell.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

public class Shell {

    // MARK: - Invoke static functions

    public static func run(
        _ command: String,
        requiresPath: Bool = false
    ) {
        Shell.user.run(command, requiresPath: requiresPath)
    }

    public static func pipe(
        _ command: String,
        requiresPath: Bool = false
    ) -> String {
        return Shell.user.pipe(command, requiresPath: requiresPath)
    }

    // MARK: - Singleton

    /**
     We now require macOS 11, so no need to detect which terminal to use.
     */
    public var shell: String = "/bin/sh"

    /** Additional exports that are sent if `requiresPath` is set to true. */
    public var exports: String = ""

    /**
     Singleton to access a user shell (with --login)
     */
    public static let user = Shell()

    /**
     Runs a shell command without using the output.
     Uses the default shell.
     
     - Parameter command: The command to run
     - Parameter requiresPath: By default, the PATH is not resolved but some binaries might require this
     */
    private func run(
        _ command: String,
        requiresPath: Bool = false
    ) {
        // Equivalent of piping to /dev/null; don't do anything with the string
        _ = Shell.pipe(command, requiresPath: requiresPath)
    }

    /**
     Runs a shell command and returns the output.
     
     - Parameter command: The command to run
     - Parameter requiresPath: By default, the PATH is not resolved but some binaries might require this
     */
    private func pipe(
        _ command: String,
        requiresPath: Bool = false
    ) -> String {
        let shellOutput = self.executeSynchronously(command, requiresPath: requiresPath)
        let hasError = (
            shellOutput.standardOutput == ""
            && shellOutput.errorOutput.lengthOfBytes(using: .utf8) > 0
        )
        return !hasError ? shellOutput.standardOutput : shellOutput.errorOutput
    }

    /**
     Runs the command and returns a `ShellOutput` object, which contains info about the process.
     
     - Parameter command: The command to run
     - Parameter requiresPath: By default, the PATH is not resolved but some binaries might require this
     - Parameter waitUntilExit: Waits for the command to complete before returning the `ShellOutput`
     */
    public func executeSynchronously(
        _ command: String,
        requiresPath: Bool = false
    ) -> Shell.Output {

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        let task = self.createTask(for: command, requiresPath: requiresPath)
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        task.waitUntilExit()

        let output = Shell.Output(
            standardOutput: String(
                data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            )!,
            errorOutput: String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            )!,
            task: task
        )

        if CommandLine.arguments.contains("--v") {
            log(task: task, output: output)
        }

        return output
    }

    /**
     Creates a new process with the correct PATH and shell.
     */
    public func createTask(for command: String, requiresPath: Bool) -> Process {
        var completeCommand = ""

        if requiresPath {
            // Basic export (PATH)
            completeCommand += "export PATH=\(Paths.binPath):$PATH && "

            // Put additional exports in between
            if !self.exports.isEmpty {
                completeCommand += "\(self.exports) && "
            }
        }

        completeCommand += command

        let task = Process()
        task.launchPath = self.shell
        task.arguments = ["--noprofile", "-norc", "--login", "-c", completeCommand]

        return task
    }

    /**
     Verbose logging for PHP Monitor's synchronous shell output.
     */
    private func log(task: Process, output: Output) {
        Log.info("")
        Log.info("==== COMMAND ====")
        Log.info("")
        Log.info("\(self.shell) \(task.arguments?.joined(separator: " ") ?? "")")
        Log.info("")
        Log.info("==== OUTPUT ====")
        Log.info("")
        dump(output)
        Log.info("")
        Log.info("==== END OUTPUT ====")
        Log.info("")
    }

    public class Output {
        public let standardOutput: String
        public let errorOutput: String
        public let task: Process

        init(standardOutput: String,
             errorOutput: String,
             task: Process) {
            self.standardOutput = standardOutput
            self.errorOutput = errorOutput
            self.task = task
        }
    }
}
