//
//  Shellable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ShellOutput: CustomStringConvertible {
    var output: String
    var isError: Bool

    var description: String {
        return output
    }
}

protocol Shellable {
    /**
     Run a command synchronously. Waits until the command is done.
     */
    func sync(_ command: String) -> ShellOutput

    /**
     Run a command asynchronously.
     */
    func pipe(_ command: String) async -> ShellOutput

    /**
     Run a command asynchronously, without returning the output of the command.
     */
    func quiet(_ command: String) async

    /**
     Attach to a given command and listen for progress updates.
     Any data that ends up in standard out or standard error becomes available.
     */
    func attach(
        _ command: String,
        didReceiveOutput: @escaping (ShellOutput) -> Void
    ) async -> ShellOutput
}
