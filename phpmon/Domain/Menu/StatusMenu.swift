//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu: NSMenu {
    func addMenuItems() {
        addPhpVersionMenuItems()
        addItem(NSMenuItem.separator())

        if Preferences.isEnabled(.displayGlobalVersionSwitcher) {
            addPhpActionMenuItems()
            addItem(NSMenuItem.separator())
        }

        addValetServicesMenuItems()
        addItem(NSMenuItem.separator())

        addValetMenuItems()
        addItem(NSMenuItem.separator())

        addConfigurationMenuItems()
        addItem(NSMenuItem.separator())

        addComposerMenuItems()
        addItem(NSMenuItem.separator())

        if PhpEnv.shared.isBusy {
            return
        }

        addStatsMenuItem()
        addItem(NSMenuItem.separator())

        addExtensionsMenuItems()
        addXdebugMenuItem()
        addPhpDoctorMenuItem()
        addItem(NSMenuItem.separator())

        addPresetsMenuItem()
        addFirstAidAndServicesMenuItems()

        addItem(NSMenuItem.separator())

        addCoreMenuItems()
    }
}
