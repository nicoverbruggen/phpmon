//
//  Command.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/10/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Command {
    
    /**
     Immediately executes a command.
     
     - Parameter path: The path of the command or program to invoke.
     - Parameter arguments: A list of arguments that are passed on.
     */
    public static func execute(path: String, arguments: [String]) -> String {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String.init(data: data, encoding: String.Encoding.utf8)!
        return output;
    }
    
}
