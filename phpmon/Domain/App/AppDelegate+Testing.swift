//
//  AppDelegate+Testing.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension AppDelegate {
    /**
     Loads system-level overrides from the testable configuration.
     Must be called before `Container.bind()` so that `Paths.init()`
     picks up the correct values for architecture and shell.
     */
    static func loadOverrides() {
        guard let path = Self.configurationPath() else { return }

        TestableConfiguration
            .loadFrom(path: path)
            .applyBeforeContainer()
    }

    /**
     Applies the full testable configuration profile (shell, filesystem,
     preferences, etc.) to the container. Must be called after `bind()`.
     */
    static func loadConfigurationProfile() {
        guard let path = Self.configurationPath() else { return }

        TestableConfiguration
            .loadFrom(path: path)
            .applyAfterContainer()
    }

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
