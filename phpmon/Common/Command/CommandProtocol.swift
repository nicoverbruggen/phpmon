//
//  CommandProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// `Sendable`: instances are handed out by the (nonisolated) `Container` and used from
// off-main / actor contexts, just like `ShellProtocol` and `FileSystemProtocol`.
nonisolated protocol CommandProtocol: Sendable {
    /**
     Immediately executes a command.

     - Parameter path: The path of the command or program to invoke.
     - Parameter arguments: A list of arguments that are passed on.
     - Parameter trimNewlines: Removes empty new line output.
     - Parameter withStandardError: Outputs standard error output to the same string output as well.
     */
    func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool,
        withStandardError: Bool
    ) -> String

    /**
     Immediately executes a command.

     - Parameter path: The path of the command or program to invoke.
     - Parameter arguments: A list of arguments that are passed on.
     - Parameter trimNewlines: Removes empty new line output.
     */
    func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool
    ) -> String

}

nonisolated extension CommandProtocol {
    func execute(
        path: String,
        arguments: [String],
        trimNewlines: Bool
    ) -> String {
        execute(
            path: path,
            arguments: arguments,
            trimNewlines: trimNewlines,
            withStandardError: false
        )
    }

}
