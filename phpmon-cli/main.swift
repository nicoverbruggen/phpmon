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

var logger = Log.shared
logger.verbosity = .warning

if CommandLine.arguments.count < 3 {
    Log.err("You must enter at least two additional arguments.")
    exit(1)
}

if CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--verbose") {
    logger.verbosity = .info
}
if CommandLine.arguments.contains("-p") || CommandLine.arguments.contains("--performance") {
    logger.verbosity = .performance
}

let argument = CommandLine.arguments[1]

if !AllowedArguments.has(argument) {
    Log.err("The supported arguments are: \(AllowedArguments.rawValues)")
    exit(1)
}

let action = AllowedArguments.init(rawValue: argument)

let switcher = PhpSwitcher.shared
PhpSwitcher.detectPhpVersions()

switch action {
case .use:
    let version = CommandLine.arguments[2]
    Log.info("Switching to PHP \(version)...")
    break
case .none:
    Log.err("Action not recognized!")
    exit(1)
}
