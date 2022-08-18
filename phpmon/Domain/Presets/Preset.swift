//
//  Preset.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct Preset: Codable, Equatable {
    let name: String
    let version: String?
    let extensions: [String: Bool]
    let configuration: [String: String?]

    public enum CodingKeys: String, CodingKey {
        case version = "php",
             name = "name",
             extensions = "extensions",
             configuration = "configuration"
    }

    /**
     What the preset does, in text form. Used to display what's going on.
     */
    var textDescription: String {
        var text = ""

        if self.version != nil {
            text += "alert.preset_description.switcher_version".localized(self.version!)
        }

        if !self.extensions.isEmpty {
            // Show a subsection header
            text += "alert.preset_description.applying_extensions".localized
        }

        for (ext, extValue) in self.extensions {
            // An extension is either enabled or disabled
            let status = extValue
                ? "alert.preset_description.enabled".localized
                : "alert.preset_description.disabled".localized
            text += "• \(ext): \(status)\n"
        }

        if !self.configuration.isEmpty {
            // Extra spacing if the previous section was extensions
            if !self.extensions.isEmpty {
                text += "\n"
            }

            // Show a subsection header
            text += "alert.preset_description.applying_config".localized
        }

        for (key, value) in self.configuration {
            // A value is either displayed, or the value is "(empty)"
            text += "• \(key)=\(value ?? "alert.preset_description.empty".localized) \n"
        }

        return text
    }

    // MARK: Applying

    /**
     Applies a given preset.
     */
    public func apply() {
        Task {
            // Was this a rollback?
            let wasRollback = (self.name == "AutomaticRevertSnapshot")

            // Save the preset that would revert this preset
            self.persistRevert()

            // Apply the PHP version if is considered a valid version
            if self.version != nil {
                if await !switchToPhpVersionIfValid() {
                    PresetHelper.rollbackPreset = nil
                    Actions.restartPhpFpm()
                    return
                }
            }

            // Apply the configuration changes first
            for conf in configuration {
                applyConfigurationValue(key: conf.key, value: conf.value ?? "")
            }

            // Apply the extension changes in-place afterward
            for ext in extensions {
                for foundExt in PhpEnv.phpInstall.extensions
                where foundExt.name == ext.key && foundExt.enabled != ext.value {
                    Log.info("Toggling extension \(foundExt.name) in \(foundExt.file)")
                    foundExt.toggle()
                    break
                }
            }

            // Reload what rollback file exists
            PresetHelper.loadRollbackPresetFromFile()

            // Restart PHP FPM process (also reloads menu, which will show the preset rollback)
            Actions.restartPhpFpm()

            // Show the correct notification
            if wasRollback {
                await LocalNotification.send(
                    title: "notification.preset_reverted_title".localized,
                    subtitle: "notification.preset_reverted_desc".localized,
                    preference: .notifyAboutPresets
                )
            } else {
                await LocalNotification.send(
                    title: "notification.preset_applied_title".localized,
                    subtitle: "notification.preset_applied_desc".localized(self.name),
                    preference: .notifyAboutPresets
                )
            }
        }
    }

    // MARK: - Apply Functionality

    private func switchToPhpVersionIfValid() async -> Bool {
        if PhpEnv.shared.currentInstall.version.short == self.version! {
            Log.info("The version we are supposed to switch to is already active.")
            return true
        }

        if PhpEnv.shared.availablePhpVersions.first(where: { $0 == self.version }) != nil {
            await MainMenu.shared.switchToPhp(self.version!)
            return true
        } else {
            DispatchQueue.main.async {
                BetterAlert().withInformation(
                    title: "alert.php_switch_unavailable.title".localized,
                    subtitle: "alert.php_switch_unavailable.subtitle".localized(version!),
                    description: "alert.php_switch_unavailable.info".localized(
                        version!,
                        PhpEnv.shared.availablePhpVersions.joined(separator: ", ")
                    )
                ).withPrimary(
                    text: "alert.php_switch_unavailable.ok".localized
                ).show()
            }
            return false
        }
    }

    private func applyConfigurationValue(key: String, value: String) {
        guard let file = PhpEnv.shared.getConfigFile(forKey: key) else {
            return
        }

        do {
            if file.has(key: key) {
                Log.info("Setting config value \(key) in \(file.filePath)")
                try file.replace(key: key, value: value)
            }
        } catch {
            Log.err("Setting \(key) to \(value) failed.")
        }
    }

    // MARK: - Menu Items

    // swiftlint:disable void_function_in_ternary
    public func getMenuItemText() -> String {
        var info = extensions.count == 1
            ? "preset.extension".localized(extensions.count)
            : "preset.extensions".localized(extensions.count)
        info += ", "
        info += configuration.count == 1
            ? "preset.preference".localized(configuration.count)
            : "preset.preferences".localized(configuration.count)

        if self.version == nil {
            return "<span style=\"font-family: '-apple-system'; font-size: 12px;\">"
            + "<b>\(name.stripped)</b><br/>"
            + "<i style=\"font-size: 11px;\">"
            + info + "</i>"
            + "</span>"
        }

        return "<span style=\"font-family: '-apple-system'; font-size: 12px;\">"
        + "<b>\(name.stripped)</b><br/>"
        + "<i style=\"font-size: 11px;\">"
        + "Switches to PHP \(version!)<br/>"
        + info + "</i>"
        + "</span>"
    }

    // MARK: - Reverting

    public var revertSnapshot: Preset {
        return Preset(
            name: "AutomaticRevertSnapshot",
            version: diffVersion(),
            extensions: diffExtensions(),
            configuration: diffConfiguration()
        )
    }

    /**
     Returns the version that was previously active, which would revert this preset's version.
     Returns nil if the version is not specified or the same.
     */
    private func diffVersion() -> String? {
        guard let version = self.version else {
            return nil
        }

        if PhpEnv.shared.currentInstall.version.short != version {
            return PhpEnv.shared.currentInstall.version.short
        } else {
            return nil
        }
    }

    /**
     Returns a list of extensions which would revert this presets's setup.
     */
    private func diffExtensions() -> [String: Bool] {
        var items: [String: Bool] = [:]

        for (key, value) in self.extensions {
            for foundExt in PhpEnv.phpInstall.extensions
            where foundExt.name == key && foundExt.enabled != value {
                // Save the original value of the extension
                items[foundExt.name] = foundExt.enabled
            }
        }

        return items
    }

    /**
     Returns a list of configuration items which would revert this presets's setup.
     */
    private func diffConfiguration() -> [String: String?] {
        var items: [String: String?] = [:]

        for (key, _) in self.configuration {
            guard let file = PhpEnv.shared.getConfigFile(forKey: key) else {
                break
            }

            items[key] = file.get(for: key)
        }

        return items
    }

    /**
     Persists the revert as a JSON file, so it can be read from a file after restarting PHP Monitor.
     */
    private func persistRevert() {
        let data = try! JSONEncoder().encode(self.revertSnapshot)

        Shell.run("mkdir -p ~/.config/phpmon")

        try! String(data: data, encoding: .utf8)!
            .write(
                toFile: "/Users/\(Paths.whoami)/.config/phpmon/preset_revert.json",
                atomically: true,
                encoding: .utf8
            )
    }
}
