//
//  Shell.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

protocol ShellDelegate: class {
    func didCompleteCommand(historyItem: ShellHistoryItem)
}

class ShellHistoryItem {
    var command: String
    var output: String
    var date: Date
    
    init(command: String, output: String) {
        self.command = command
        self.output = output
        self.date = Date()
    }
}

class Shell {
    
    static let shared = Shell()
    
    var history : [ShellHistoryItem] = []
    
    var delegate : ShellDelegate?
    
    /// Runs a shell command without using the description.
    public func run(_ command: String) {
        // Equivalent of piping to /dev/null; don't do anything with the string
        _ = self.pipe(command)
    }
    
    /// Runs a shell command and returns the output.
    public func pipe(_ command: String) -> String {
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
        )!.replacingOccurrences(
            of: "\u{1B}(B\u{1B}[m",
            with: ""
        ) as String
        
        let historyItem = ShellHistoryItem(command: command, output: output)
        history.append(historyItem)
        // Keep the last 100 items
        history = history.suffix(100)
        print(history.count)
        delegate?.didCompleteCommand(historyItem: historyItem)
        
        return output
    }
}
