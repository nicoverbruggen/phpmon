//
//  CustomPrefs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct CustomPrefs: Decodable {
    let scanApps: [String]?
    let presets: [Preset]?
    let services: [String]?
    let environmentVariables: [String: String]?

    var exportAsString: String {
        return self.environmentVariables!
            .map { (key, value) in
                return "export \(key)=\(value)"
            }
            .joined(separator: "&&")
    }

    public func hasPresets() -> Bool {
        return self.presets != nil && !self.presets!.isEmpty
    }

    public func hasServices() -> Bool {
        return self.services != nil && !self.services!.isEmpty
    }

    public func hasEnvironmentVariables() -> Bool {
        return self.environmentVariables != nil && !self.environmentVariables!.keys.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case scanApps = "scan_apps"
        case presets = "presets"
        case services = "services"
        case environmentVariables = "export"
    }
}

extension Preferences {
    func loadCustomPreferences() async {
        // Ensure the configuration directory is created if missing
        await App.shared.container.shell.quiet("mkdir -p ~/.config/phpmon")

        // Move the legacy file
        await moveOutdatedConfigurationFile()

        // Attempt to load the file if it exists
        let url = URL(fileURLWithPath: "\(App.shared.container.paths.homePath)/.config/phpmon/config.json")
        if App.shared.container.filesystem.fileExists(url.path) {

            Log.info("A custom ~/.config/phpmon/config.json file was found. Attempting to parse...")
            loadCustomPreferencesFile(url)
        } else {
            Log.info("There was no /.config/phpmon/config.json file to be loaded.")
        }
    }

    func moveOutdatedConfigurationFile() async {
        if App.shared.container.filesystem.fileExists("~/.phpmon.conf.json") && !App.shared.container.filesystem.fileExists("~/.config/phpmon/config.json") {
            Log.info("An outdated configuration file was found. Moving it...")
            await App.shared.container.shell.quiet("cp ~/.phpmon.conf.json ~/.config/phpmon/config.json")
            Log.info("The configuration file was copied successfully!")
        }
    }

    func loadCustomPreferencesFile(_ url: URL) {
        do {
            customPreferences = try JSONDecoder().decode(
                CustomPrefs.self,
                from: try! String(contentsOf: url, encoding: .utf8).data(using: .utf8)!
            )

            Log.info("The ~/.config/phpmon/config.json file was successfully parsed.")

            if customPreferences.hasPresets() {
                Log.info("There are \(customPreferences.presets!.count) custom presets.")
            }

            if customPreferences.hasServices() {
                Log.info("There are custom services: \(customPreferences.services!)")
            }

            if customPreferences.hasEnvironmentVariables() {
                Log.info("Configuring the additional exports...")
                if let shell = App.shared.container.shell as? RealShell {
                    shell.exports = customPreferences.exportAsString
                }
            }
        } catch {
            Log.warn("The ~/.config/phpmon/config.json file seems to be missing or malformed.")
        }
    }
}
