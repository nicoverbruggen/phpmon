//
//  StatusMenu+Driver.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/07/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAlert

extension StatusMenu {
    @MainActor func addLiteModeMenuItem() {
        addItems([
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_lite_mode".localized, action: #selector(MainMenu.openLiteModeInfo))
        ])
    }

    @MainActor func addValetVersionItem() {
        if let version = Valet.shared.version {
            var items = [
                NSMenuItem.separator(),
                NSMenuItem(title: "mi_driver".localized("Valet \(version.text)"),
                           action: nil, customImage: "ValetDriverIcon")
            ]

            if let latest = Valet.shared.latestVersion {
                if latest.isNewerThan(version) {
                    items.append(
                        NSMenuItem(title: "mi_valet_upgrade_action".localized(latest.text),
                                   action: #selector(MainMenu.showValetUpgradeAvailableAlert),
                                   systemImage: "arrow.up.square.fill")
                    )
                }
            }

            addItems(items)
        }
    }
}
