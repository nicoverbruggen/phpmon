//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu: NSMenu {
    nonisolated let container: Container

    nonisolated init(container: Container) {
        self.container = container
        super.init(title: "")
    }

    // `NSMenu`'s initializers are nonisolated in the AppKit SDK; match that so these
    // (otherwise main-actor-by-default) overrides don't mismatch the superclass.
    nonisolated override init(title: String) {
        self.container = App.shared.container
        super.init(title: title)
    }

    nonisolated required init(coder: NSCoder) {
        self.container = App.shared.container
        super.init(coder: coder)
    }

    // swiftlint:disable cyclomatic_complexity
    @MainActor func addMenuItems() {
        addPhpVersionMenuItems()
        addItem(NSMenuItem.separator())

        if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayGlobalVersionSwitcher) {
            addPhpActionMenuItems()
            addItem(NSMenuItem.separator())
        }

        if container.phpEnvs.phpInstall != nil && container.valet.installed && container.preferences.isEnabled(.displayServicesManager) {
            addServicesManagerMenuItem()
            addItem(NSMenuItem.separator())
        }

        if container.valet.version != nil && container.preferences.isEnabled(.displayValetIntegration) {
            addValetMenuItems()
            addItem(NSMenuItem.separator())
        }

        if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayPhpConfigFinder) {
            addConfigurationMenuItems()
            addItem(NSMenuItem.separator())
        }

        if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayComposerToolkit) {
            addComposerMenuItems()
            addItem(NSMenuItem.separator())
        }

        if !container.phpEnvs.isBusy {
            if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayLimitsWidget) {
                addStatsMenuItem()
                addItem(NSMenuItem.separator())
            }

            if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayExtensions) {
                addExtensionsMenuItems()
                NSMenuItem.separator()

                addXdebugMenuItem()
            }

            addPhpDoctorMenuItem()

            if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayPresets) {
                addPresetsMenuItem()
            }

            if container.phpEnvs.phpInstall != nil && container.preferences.isEnabled(.displayMisc) {
                addFirstAidAndServicesMenuItems()
            }
        }

        addItem(NSMenuItem.separator())

        addPreferencesMenuItems()

        if container.preferences.isEnabled(.displayDriver) {
            if container.valet.installed {
                // Add the menu item displaying the driver information
                addValetVersionItem()
            } else {
                // No driver, using Standalone Mode (internally: lite mode)
                addLiteModeMenuItem()
            }
        }

        addCoreMenuItems()
    }
    // swiftlint:enable cyclomatic_complexity
}
