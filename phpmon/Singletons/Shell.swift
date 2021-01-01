//
//  Shell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Shell {
    
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
    
    public static func fileExists(_ filePath: String) -> Bool {
        return Shell.user.pipe(
            "if [ -f \(filePath) ]; then echo \"Y\"; fi"
        ).contains("Y")
    }
}
