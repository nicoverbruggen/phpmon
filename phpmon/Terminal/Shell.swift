//
//  Shell.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Shell {
    
    public static func execute(command: String) -> String
    {
        let task = Process()
        task.launchPath = "/bin/bash"
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
