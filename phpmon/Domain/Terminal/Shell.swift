//
//  Shell.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Shell {
    
    // MARK: - Invoke static functions
    
    public static func run(_ command: String) {
        Shell.user.run(command)
    }
    
    public static func pipe(_ command: String) -> String {
        return Shell.user.pipe(command)
    }
    
    // MARK: - Singleton
    
    var shell: String
    
    init() {
        // Determine if we're using macOS Catalina or newer (that support /bin/zsh as default shell)
        let at_least_10_15 = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            .init(majorVersion: 10, minorVersion: 15, patchVersion: 0))
    
        // If macOS Mojave is being used, we'll default to /bin/bash
        shell = at_least_10_15
            ? "/bin/sh"
            : "/bin/bash"
        
        print(at_least_10_15
            ? "Detected recent macOS (> 10.15): defaulting to /bin/sh"
            : "Detected older macOS (< 10.15): defaulting to /bin/bash"
        )
    }
    
    /**
     Singleton to access a user shell (with --login)
     */
    static let user = Shell()
    
    /**
     Runs a shell command without using the output.
     Uses the default shell.
     
     - Parameter command: The command to run
     */
    func run(_ command: String) {
        // Equivalent of piping to /dev/null; don't do anything with the string
        _ = pipe(command)
    }
    
    /**
     Runs a shell command and returns the output.
     
     - Parameter command: The command to run
     - Parameter shell: Path to the shell to invoke
     */
    func pipe(_ command: String) -> String {
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.launchPath = self.shell
        task.arguments = ["--login", "-c", command]
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        
        if (output == "" && error.lengthOfBytes(using: .utf8) > 0) {
            return error
        }

        return output
    }
    
    /**
     Checks if a file exists at the provided path.
     Uses `/bin/echo` instead of the `builtin` (which does not support `-n`).
     */
    public static func fileExists(_ path: String) -> Bool {
        return Shell.pipe("if [ -f \(path) ]; then /bin/echo -n \"0\"; fi") == "0"
    }
    
}
