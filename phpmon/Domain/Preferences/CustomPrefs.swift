//
//  CustomPrefs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// `nonisolated`: decoded on the concurrent pool (the config file read is blocking
// I/O) and stored behind `Preferences`' lock-guarded state.
// `Sendable`: an immutable value type (all stored properties are `let` value types),
// required so it can live inside `Preferences`' `OSAllocatedUnfairLock`.
nonisolated struct CustomPrefs: Decodable, Sendable {
    let scanApps: [String]?
    let presets: [Preset]?
    let services: [String]?
    let environmentVariables: [String: String]?

    public func hasPresets() -> Bool {
        return self.presets != nil && !self.presets!.isEmpty
    }

    public func hasServices() -> Bool {
        return self.services != nil && !self.services!.isEmpty
    }

    public func hasEnvironmentVariables() -> Bool {
        guard let variables = self.environmentVariables else {
            return false
        }

        return !variables.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case scanApps = "scan_apps"
        case presets = "presets"
        case services = "services"
        case environmentVariables = "export"
    }
}

// `nonisolated`: matches `Preferences` itself (a nonisolated leaf whose mutable
// state is lock-guarded); the file read runs via `offMain` and must not be
// isolated to the main actor.
nonisolated extension Preferences {
    func loadCustomPreferences() async {
        // Ensure the configuration directory is created if missing
        await container.shell.pipe("mkdir -p ~/.config/phpmon")

        // Move the legacy file
        await moveOutdatedConfigurationFile()

        // Attempt to load the file if it exists
        if container.filesystem.fileExists("~/.config/phpmon/config.json") {
            Log.info("A custom ~/.config/phpmon/config.json file was found. Attempting to parse...")
            // The file read is blocking I/O, so hop to the concurrent pool
            await offMain { self.loadCustomPreferencesFile() }
        } else {
            Log.info("There was no /.config/phpmon/config.json file to be loaded.")
        }
    }

    func moveOutdatedConfigurationFile() async {
        if container.filesystem.fileExists("~/.phpmon.conf.json")
            && !container.filesystem.fileExists("~/.config/phpmon/config.json") {
            Log.info("An outdated configuration file was found. Moving it...")
            await container.shell.pipe("cp ~/.phpmon.conf.json ~/.config/phpmon/config.json")
            Log.info("The configuration file was copied successfully!")
        }
    }

    func loadCustomPreferencesFile() {
        guard let data = try? container.filesystem.getStringFromFile("~/.config/phpmon/config.json").data(using: .utf8) else {
            Log.warn("The ~/.config/phpmon/config.json file could not be read as UTF-8.")
            return
        }

        guard let parsedPreferences = try? JSONDecoder().decode(CustomPrefs.self, from: data) else {
            Log.warn("The ~/.config/phpmon/config.json file seems to be malformed.")
            return
        }

        Log.info("The ~/.config/phpmon/config.json file was successfully parsed.")

        customPreferences = parsedPreferences

        if customPreferences.hasPresets() {
            Log.info("There are \(customPreferences.presets!.count) custom presets.")
        }

        if customPreferences.hasServices() {
            Log.info("There are custom services: \(customPreferences.services!)")
        }

        if customPreferences.hasEnvironmentVariables() {
            let exports = customPreferences.environmentVariables ?? [:]

            Log.info("Configuring the additional exports...")
            Log.info("Custom exports: \(exports.description)")

            // Assign the new exports values
            container.shell.exports = exports
        }
    }
}
