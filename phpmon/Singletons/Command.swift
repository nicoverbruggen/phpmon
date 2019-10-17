//
//  Command.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/10/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Command {

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
    
    public static func experiment() {
        /*
        print("Running '/usr/local/bin/php -v' directly...")
        print("========================================")
        var start = DispatchTime.now()
        print(Command.execute(path: "/usr/local/bin/php", arguments: ["-v"]))
        var end = DispatchTime.now()
        var nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        var timeInterval = Double(nanoTime) / 1_000_000_000
        print("Time to run command directly: \(timeInterval) seconds")
        
        print("")
        print("Running 'bash -> php -v'...")
        print("========================================")
        start = DispatchTime.now()
        print(Shell.user.pipe("php -v"))
        end = DispatchTime.now()
        nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        timeInterval = Double(nanoTime) / 1_000_000_000
        print("Time to run command via bash: \(timeInterval) seconds")
        */
    }
    
}
