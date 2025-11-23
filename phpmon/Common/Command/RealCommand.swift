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
        task.launchPath = path
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe

        if withStandardError {
            task.standardError = pipe
        }

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String.init(data: data, encoding: String.Encoding.utf8)!

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
