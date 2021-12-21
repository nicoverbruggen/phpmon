//
//  main.swift
//  phpmon-cli
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

let toolver = "1.0"

let log = Log.shared

if CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--verbose") {
    Log.shared.verbosity = .info
}
if CommandLine.arguments.contains("-p") || CommandLine.arguments.contains("--performance") {
    Log.shared.verbosity = .performance
}

var argument = "help"
if CommandLine.arguments.count > 1 {
    argument = CommandLine.arguments[1]
}

if !AllowedArguments.has(argument) {
    Log.err("The supported arguments are: \(AllowedArguments.rawValues)")
    exit(1)
}

let action = AllowedArguments.init(rawValue: argument)

switch action {
case .use, .performSwitch:
    if !Shell.fileExists("\(Paths.binPath)/php") {
        Log.err("PHP is currently not linked. Attempting to link `php` at least...")
        _ = Shell.user.executeSynchronously("brew link php", requiresPath: true)
    }
    
    let switcher = PhpSwitcher.shared
    PhpSwitcher.detectPhpVersions()
    
    if CommandLine.arguments.count < 3 {
        Log.err("You must enter at least two additional arguments when using this command.")
        exit(1)
    }
    
    let version = CommandLine.arguments[2].replacingOccurrences(of: "php@", with: "")
    if switcher.availablePhpVersions.contains(version) {
        Log.info("Switching to PHP \(version)...")
        Actions.switchToPhpVersion(
            version: version,
            availableVersions: switcher.availablePhpVersions,
            completed: {
                Log.info("The switch has been completed.")
                exit(0)
            }
        )
    } else {
        Log.err("A PHP installation with version \(version) is not installed.")
        Log.err("The installed versions are: \(switcher.availablePhpVersions.joined(separator: ", ")).")
        Log.err("If this version is available, you may be able to install it by using `brew install php@\(version)`.")
        exit(1)
    }
    
case .help:
    print("""
    ===============================================================
    PHP MONITOR CLI \(toolver)
    by Nico Verbruggen
    ===============================================================
    
    Gives access to the quick version switcher from PHP Monitor,
    but without the GUI and 100% of the speed!
    
    SUPPORTED COMMANDS
    
    * use {version}:      Switch to a specific version of PHP.
                          (e.g. `phpmon-cli use 8.0`)
    * switch {version}:   Alias for the `use` command.
    * help:               Show this help.
    
    SUPPORTED FLAGS
    
    * `-v / --verbose`:   Enables verbose mode.
    * `-p / --perf`:      Enables performance mode.
    
    """)
    exit(0)
case .none:
    Log.err("Action not recognized!")
    exit(1)
}

RunLoop.main.run()
