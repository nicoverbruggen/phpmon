//
//  CustomPrefs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct CustomPrefs: Decodable {
    let scanApps: [String]
    let presets: [Preset]

    private enum CodingKeys: String, CodingKey {
        case scanApps = "scan_apps"
        case presets = "presets"
    }

    struct Preset: Decodable {
        let name: String
        let extensions: [String: Bool]
        let configuration: [String: String?]

        public func apply() {
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
}
