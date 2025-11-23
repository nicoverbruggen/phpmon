//
//  LoginItemManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/02/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import AppKit
import ServiceManagement

@available(macOS 13.0, *)
class LoginItemManager {
    func loginItemIsEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    func disableLoginItem() {
        try? SMAppService.mainApp.unregister()
    }

    func enableLoginItem() {
        try? SMAppService.mainApp.register()
    }
}
