//
//  PresetHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PresetHelper {

    static var rollbackPreset: Preset?

    // MARK: - Reloading Configuration

    public static func loadRollbackPresetFromFile() {
        guard let revert = try? String(
            contentsOfFile: "\(App.shared.container.paths.homePath)/.config/phpmon/preset_revert.json",
            encoding: .utf8
        ) else {
            PresetHelper.rollbackPreset = nil
            return
        }

        guard let preset = try? JSONDecoder().decode(
            Preset.self,
            from: revert.data(using: .utf8)!
        ) else {
            PresetHelper.rollbackPreset = nil
            return
        }

        PresetHelper.rollbackPreset = preset
    }

}
