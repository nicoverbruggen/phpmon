//
//  CLI.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct CLI {
    /**
     Check if any verbose logging is enabled.
     Even in production releases, verbose logging can be enabled.
     */
    static func checkCommandLineArguments() {
        if CommandLine.arguments.contains("--v") {
            Log.shared.verbosity = .performance
            Log.info("Extra verbose mode has been activated.")
        }

        if CommandLine.arguments.contains("--cli") {
            Log.shared.verbosity = .cli
            Log.info("Extra CLI mode has been activated via --cli flag.")
        }

        if CommandLine.arguments.contains("--ch") {
            Log.info("Displaying command history window (`--ch` flag).")
            CommandHistoryWC.show()
        }
    }

    /**
     Loads and applies a testable configuration profile if one was
     provided via the `--configuration:` launch argument.
     */
    static func loadConfigurationProfile() {
        guard let path = Self.configurationPath() else { return }

        TestableConfiguration
            .loadFrom(path: path)
            .apply()
    }

    /**
     Check if a configuration profile was configured via launch parameter.
     */
    private static func configurationPath() -> String? {
        if let path = CommandLine.arguments
            .first(where: { $0.matches(pattern: "--configuration:*") })?
            .replacing("--configuration:", with: "") {
            Log.info("The configuration with path `\(path)` is being requested...")
            return path
        }

        return nil
    }
}
