//
//  Shell.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Shell {
    
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
    var shell: String = "/bin/sh"
    
    /**
     Singleton to access a user shell (with --login)
     */
    static let user = Shell()
    
    /**
     Runs a shell command without using the output.
     Uses the default shell.
     
     - Parameter command: The command to run
     - Parameter requiresPath: By default, the PATH is not resolved but some binaries might require this
     */
    func run(
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
    func pipe(
        _ command: String,
        requiresPath: Bool = false
    ) -> String {
        let shellOutput = self.execute(command, requiresPath: requiresPath)
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
    func execute(
        _ command: String,
        requiresPath: Bool = false,
        waitUntilExit: Bool = false
    ) -> ShellOutput {
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let tailoredCommand = requiresPath
            ? "export PATH=\(Paths.binPath):$PATH && \(command)"
            : command
        
        task.launchPath = self.shell
        task.arguments = ["--noprofile", "-norc", "--login", "-c", tailoredCommand]
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        
        if waitUntilExit {
            task.waitUntilExit()
        }
    
        return ShellOutput(
            standardOutput: String(
                data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8
            )!,
            errorOutput: String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8
            )!,
            task: task
        )
    }
    
    /**
     Checks if a file exists at the provided path.
     Uses `/bin/echo` instead of the `builtin` (which does not support `-n`).
     */
    public static func fileExists(_ path: String) -> Bool {
        let escapedPath = path.replacingOccurrences(of: " ", with: "\\ ")
        return Shell.pipe("if [ -f \(escapedPath) ]; then /bin/echo -n \"0\"; fi") == "0"
    }
}

class ShellOutput {
    let standardOutput: String
    let errorOutput: String
    let task: Process
    
    init(standardOutput: String,
         errorOutput: String,
         task: Process) {
        self.standardOutput = standardOutput
        self.errorOutput = errorOutput
        self.task = task
    }
}
