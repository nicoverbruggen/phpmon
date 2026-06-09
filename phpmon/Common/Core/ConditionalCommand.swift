//
//  ConditionalCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

/**
 A single shell command that may be conditionally included in a sequence.

 This lets call sites describe a list of commands declaratively, opting individual
 commands in or out with `when:`, instead of imperatively building up an array:

 ```swift
 let commands: [ConditionalCommand] = [
     .command("\(brew) tap shivammathur/php"),
     .command("\(brew) trust --tap shivammathur/php", when: supportsTrust),
     .command("\(brew) install shivammathur/php/php")
 ]
 try await shell.attach(commands.chained, ...)
 ```
 */
struct ConditionalCommand {
    let command: String
    let isIncluded: Bool

    static func command(_ command: String, when isIncluded: Bool = true) -> ConditionalCommand {
        return ConditionalCommand(command: command, isIncluded: isIncluded)
    }
}

extension Array where Element == ConditionalCommand {
    /// The command strings that should actually run, in order, with excluded commands dropped.
    var included: [String] {
        return compactMap { $0.isIncluded ? $0.command : nil }
    }

    /// The included commands chained together with `&&` for a single shell invocation.
    var chained: String {
        return included.joined(separator: " && ")
    }
}
