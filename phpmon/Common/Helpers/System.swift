//
//  System.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 Run a simple blocking Shell command on the user's own system.
 Avoid using this method in favor of the fakeable Shell class unless needed for express system operations.
 */
public func system(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

    return output
}

public func system_quiet(_ command: String) {
    _ = system(command)
}
