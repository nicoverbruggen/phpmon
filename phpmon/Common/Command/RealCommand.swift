//
//  Command.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

public class RealCommand: CommandProtocol {
    public func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool,
        withStandardError: Bool
    ) -> String {
        let task = Process()
        var output = ""

        task.launchPath = path
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe

        if withStandardError {
            task.standardError = pipe
        }

        task.launch()
        task.waitUntilExit()

        defer {
            try? pipe.fileHandleForReading.close()
        }

        // Handle termination
        if task.terminationReason == .uncaughtSignal {
            Log.err("The command `\(path) w/ args: \(arguments)` likely crashed. Returning UNCAUGHT_SIGNAL.")
            return "PHPMON_COMMAND_UNCAUGHT_SIGNAL"
        }

        // Try reading from file handle and close it
        if let data = try? pipe.fileHandleForReading.readToEnd() {
            if let string = String(data: data, encoding: .utf8) {
                output = string
            } else {
                return "PHPMON_FILE_HANDLE_READ_FAILURE"
            }
        }

        // Trim newline output if necessary
        if trimNewlines {
            return output.components(separatedBy: .newlines)
                .filter({ !$0.isEmpty })
                .joined(separator: "\n")
        }

        return output
    }

    public func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool = false
    ) -> String {
        self.execute(
            path: path,
            arguments: arguments,
            trimNewlines: trimNewlines,
            withStandardError: false
        )
    }
}
