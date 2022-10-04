//
//  Shellable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

enum ShellStream {
    case stdOut, stdErr, stdIn
}

struct ShellOutput {
    var out: String
    var err: String

    var hasError: Bool {
        return err.lengthOfBytes(using: .utf8) > 0
    }

    static func out(_ out: String?, _ err: String? = nil) -> ShellOutput {
        return ShellOutput(out: out ?? "", err: err ?? "")
    }

    static func err(_ err: String?) -> ShellOutput {
        return ShellOutput(out: "", err: err ?? "")
    }
}

protocol Shellable {
    /**
     Run a command asynchronously.
     Returns the most relevant output (prefers error output if it exists).
     */
    func pipe(_ command: String) async -> ShellOutput

    /**
     Run a command asynchronously, without returning the output of the command.
     Returns the most relevant output (prefers error output if it exists).
     */
    func quiet(_ command: String) async

    /**
     Runs a command asynchronously, and fires closure with `stdout` or `stderr` data as it comes in.

     You can specify how long this task should run.
     The process will always be terminated after the specified time interval.
     (Whether it is complete or not.)

     Unlike `sync`, `pipe` and `quiet`, you can capture both `stdout` and `stderr` with this mechanism.
     The end result is still the most relevant output (where error output is preferred if it exists).
     */
    func attach(
        _ command: String,
        didReceiveOutput: @escaping (String, ShellStream) -> Void,
        withTimeout timeout: TimeInterval
    ) async throws -> (Process, ShellOutput)
}

enum ShellError: Error {
    case timedOut
}
