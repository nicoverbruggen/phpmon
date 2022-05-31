//
//  Preset.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct Preset: Decodable {
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

    public func apply() {
        Task {
            // Apply the PHP version if is considered a valid version
            if self.version != nil {
                await switchToPhpVersionIfValid()
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

            Actions.restartPhpFpm()
        }
    }

    private func switchToPhpVersionIfValid() async {
        if PhpEnv.shared.currentInstall.version.short == self.version! {
            Log.info("The version we are supposed to switch to is already active.")
            return
        }

        if PhpEnv.shared.availablePhpVersions.first(where: { $0 == self.version }) != nil {
            await MainMenu.shared.switchToPhp(self.version!)
            return
        } else {
            DispatchQueue.main.async {
                BetterAlert()
                    .withInformation(
                        title: "PHP version unavailable",
                        subtitle: "You have specified a PHP version (\(version!)) that is unavailable.",
                        description: "Please make sure this version of PHP is installed "
                        + "and you can switch to it in the dropdown. "
                        + "Currently supported versions include: "
                        + "\(PhpEnv.shared.availablePhpVersions.joined(separator: ", "))."
                    )
                    .withPrimary(text: "OK")
                    .show()
            }
            return
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
}
