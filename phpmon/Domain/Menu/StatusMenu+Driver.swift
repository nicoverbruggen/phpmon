//
//  StatusMenu+Driver.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/07/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension StatusMenu {
    @MainActor func addLiteModeMenuItem() {
        addItems([
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_lite_mode".localized, action: #selector(MainMenu.openLiteModeInfo))
        ])
    }

    @MainActor func addValetVersionItem() {
        if let version = Valet.shared.version {
            addItems([
                NSMenuItem.separator(),
                NSMenuItem(title: "mi_driver".localized("Valet \(version.text)"),
                           action: nil, customImage: "ValetDriverIcon")
            ])
        }
    }
}
