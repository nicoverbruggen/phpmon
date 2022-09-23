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

        if Preferences.isEnabled(.displayServicesManager) {
            addServicesManagerMenuItem()
            addItem(NSMenuItem.separator())
        }

        if Preferences.isEnabled(.displayValetIntegration) {
            addValetMenuItems()
            addItem(NSMenuItem.separator())
        }

        if Preferences.isEnabled(.displayPhpConfigFinder) {
            addConfigurationMenuItems()
            addItem(NSMenuItem.separator())
        }

        if Preferences.isEnabled(.displayComposerToolkit) {
            addComposerMenuItems()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.shared.isBusy {
            return
        }

        if Preferences.isEnabled(.displayLimitsWidget) {
            addStatsMenuItem()
            addItem(NSMenuItem.separator())
        }

        if Preferences.isEnabled(.displayExtensions) {
            addExtensionsMenuItems()
            NSMenuItem.separator()

            addXdebugMenuItem()
        }

        addPhpDoctorMenuItem()

        if Preferences.isEnabled(.displayPresets) {
            addPresetsMenuItem()
        }

        if Preferences.isEnabled(.displayMisc) {
            addFirstAidAndServicesMenuItems()
        }

        addItem(NSMenuItem.separator())

        addCoreMenuItems()
    }
}
