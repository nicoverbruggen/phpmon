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

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayGlobalVersionSwitcher) {
            addPhpActionMenuItems()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayServicesManager) {
            addServicesManagerMenuItem()
            addItem(NSMenuItem.separator())
        }

        if Valet.shared.version != nil && Preferences.isEnabled(.displayValetIntegration) {
            addValetMenuItems()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayPhpConfigFinder) {
            addConfigurationMenuItems()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayComposerToolkit) {
            addComposerMenuItems()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.shared.isBusy {
            return
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayLimitsWidget) {
            addStatsMenuItem()
            addItem(NSMenuItem.separator())
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayExtensions) {
            addExtensionsMenuItems()
            NSMenuItem.separator()

            addXdebugMenuItem()
        }

        addPhpDoctorMenuItem()

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayPresets) {
            addPresetsMenuItem()
        }

        if PhpEnv.phpInstall != nil && Preferences.isEnabled(.displayMisc) {
            addFirstAidAndServicesMenuItems()
        }

        addItem(NSMenuItem.separator())

        addCoreMenuItems()
    }
}
