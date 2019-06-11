//
//  Shell.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Shell {
    public static func execute(command: String) -> String?
    {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output
    }
    
    public static func extractPhpVersion() -> String
    {
        // Get the info about the PHP installation
        let output = self.execute(command: "php -v")
        // Get everything before "(cli)" (PHP X.X.X (cli) ...)
        var version = output!.components(separatedBy: " (cli)")[0]
        // Strip away the text before the version number
        version = version.components(separatedBy: "PHP ")[1]
        // Next up, let's strip away the minor version number
        let segments = version.components(separatedBy: ".")
        // Get the first two elements
        return segments[0...1].joined(separator: ".")
    }
}
