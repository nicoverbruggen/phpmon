//
//  main.swift
//  phpmon-cli
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

// First, let's read the initial command line argument

// REFACTOR REQUIRED
// Information about the Homebrew linked alias
// Information about the PHP versions
// etc.: needs to be stored in a separate object we can instantiate here and in PHP Monitor.

print(CommandLine.arguments)

if CommandLine.arguments.count != 3 {
    print("You must enter two arguments.")
    exit(1)
}

let argument = CommandLine.arguments[1]

if !AllowedArguments.has(argument) {
    print("The supported arguments are: \(AllowedArguments.rawValues)")
    exit(1)
}

let action = AllowedArguments.init(rawValue: argument)

let switcher = PhpSwitcher.shared
PhpSwitcher.detectPhpVersions()

switch action {
case .use:
    let version = CommandLine.arguments[2]
    print("Switching to PHP \(version)...")
    break
case .none:
    print("Action not recognized!")
    exit(1)
}
