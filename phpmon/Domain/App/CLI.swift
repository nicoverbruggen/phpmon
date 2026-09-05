//
//  CLI.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

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
     Applies system context overrides (architecture, shell) from the
     testable configuration before the container is bound. This is
     important because this information is required for the container
     to be able to correctly determine some key information about the
     system itself. (System context is effectively fixed once set.)
     */
    static func applySystemContext() {
        configuration()?.beforeBind()
    }

    /**
     Loads and applies a testable configuration profile if one was
     provided by the UI tests or the `--configuration:` launch argument.
     */
    static func loadConfigurationProfile() {
        configuration()?.afterBind()
    }

    private static func configuration() -> TestableConfiguration? {
        #if DEBUG
        // Pass UI fixtures directly instead of reading the runner's private app container.
        if let json = ProcessInfo.processInfo.environment["PHPMON_TEST_CONFIGURATION"] {
            return try! JSONDecoder().decode(TestableConfiguration.self, from: Data(json.utf8))
        }
        #endif

        if let path = CommandLine.arguments
            .first(where: { $0.matches(pattern: "--configuration:*") })?
            .replacing("--configuration:", with: "") {
            Log.info("The configuration with path `\(path)` is being requested...")
            return TestableConfiguration.loadFrom(path: path)
        }

        return nil
    }
}
