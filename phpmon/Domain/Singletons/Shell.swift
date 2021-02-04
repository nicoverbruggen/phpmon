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
    
    public static func pipe(_ command: String, shell: String = "/bin/sh") -> String {
        Shell.user.pipe(command, shell: shell)
    }
    
    // MARK: - Singleton
    
    /**
     Singleton to access a user shell (with --login)
     */
    static let user = Shell()
    
    /**
     Runs a shell command without using the output.
     Uses the default shell.
     
     - Parameter command: The command to run
     */
    public func run(_ command: String) {
        // Equivalent of piping to /dev/null; don't do anything with the string
        _ = self.pipe(command)
    }
    
    /**
     Runs a shell command and returns the output.
     
     - Parameter command: The command to run
     - Parameter shell: Path to the shell to invoke
     */
    public func pipe(_ command: String, shell: String = "/bin/sh") -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = shell
        task.arguments = ["--login", "-c", command]
        task.standardOutput = pipe
        task.launch()

        return String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!
    }
    
    /**
     Checks if a file exists at the provided path.
     */
    public static func fileExists(_ path: String) -> Bool {
        return Shell.pipe(
            "if [ -f \(path) ]; then echo \"PHP_Y_FE\"; fi"
        ).contains("PHP_Y_FE")
    }
}
