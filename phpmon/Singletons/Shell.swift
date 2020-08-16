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
        task.launchPath = shell
        task.arguments = ["--login", "-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        let output: String = NSString(
            data: data,
            encoding: String.Encoding.utf8.rawValue
        )! as String

        return output
    }
}
