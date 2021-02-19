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
        Shell.user.pipe(command)
    }
    
    // MARK: - Singleton
    
    var shell = "/bin/sh"
    
    init() {
        // Determine if we're using macOS Catalina or newer (that support /bin/zsh as default shell)
        let at_least_10_15 = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            .init(majorVersion: 10, minorVersion: 15, patchVersion: 0))
    
        // If macOS Mojave is being used, we'll default to /bin/bash
        self.shell = at_least_10_15 ? "/bin/sh" : "/bin/bash"
        print(at_least_10_15 ? "Detected recent macOS (> 10.15): defaulting to /bin/sh"
            : "Detected older macOS (< 10.15): so defaulting to /bin/bash")
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
        _ = self.pipe(command)
    }
    
    /**
     Runs a shell command and returns the output.
     
     - Parameter command: The command to run
     - Parameter shell: Path to the shell to invoke
     */
    func pipe(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = self.shell
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
