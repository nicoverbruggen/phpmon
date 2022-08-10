//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu: NSMenu {

    func addPhpVersionMenuItems() {
        if PhpEnv.phpInstall.version.error {
            for message in ["mi_php_broken_1", "mi_php_broken_2", "mi_php_broken_3", "mi_php_broken_4"] {
                addItem(NSMenuItem(title: message.localized, action: nil, keyEquivalent: ""))
            }
            return
        }

        let phpVersionText = "\("mi_php_version".localized) \(PhpEnv.phpInstall.version.long)"
        addItem(HeaderView.asMenuItem(text: phpVersionText))
    }

    func addPhpActionMenuItems() {
        if PhpEnv.shared.isBusy {
            addItem(NSMenuItem(title: "mi_busy".localized, action: nil, keyEquivalent: ""))
            return
        }

        if PhpEnv.shared.availablePhpVersions.isEmpty {
            return
        }

        self.addSwitchToPhpMenuItems()
        self.addItem(NSMenuItem.separator())

        self.addItem(ServicesView.asMenuItem())
        self.addItem(NSMenuItem.separator())
    }

    func addValetMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_valet".localized))
        self.addItem(NSMenuItem(
            title: "mi_valet_config".localized, action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
        self.addItem(NSMenuItem(
            title: "mi_domain_list".localized, action: #selector(MainMenu.openDomainList), keyEquivalent: "l"))
        self.addItem(NSMenuItem.separator())
    }

    func addRemainingMenuItems() {
        self.addConfigurationMenuItems()

        self.addItem(NSMenuItem.separator())

        self.addComposerMenuItems()

        if PhpEnv.shared.isBusy {
            return
        }

        self.addItem(NSMenuItem.separator())

        self.addStatsMenuItem()

        self.addItem(NSMenuItem.separator())

        self.addExtensionsMenuItems()

        self.addItem(NSMenuItem.separator())

        self.addXdebugMenuItem()
        self.addPresetsMenuItem()

        self.addFirstAidAndServicesMenuItems()
    }

    func addWarningsMenuItem() {
        if !WarningManager.shared.hasWarnings() {
            return
        }

        self.addItem(NSMenuItem.separator())

        let count = WarningManager.shared.warnings.count
        self.addItem(NSMenuItem(title: (count == 1 ? "mi_warning" : "mi_warnings").localized(count),
                                action: #selector(MainMenu.openWarnings), keyEquivalent: ""))
    }

    func addCoreMenuItems() {
        self.addItem(NSMenuItem.separator())

        self.addItem(NSMenuItem(title: "mi_preferences".localized,
                                action: #selector(MainMenu.openPrefs), keyEquivalent: ","))
        self.addItem(NSMenuItem(title: "mi_check_for_updates".localized,
                                action: #selector(MainMenu.checkForUpdates), keyEquivalent: ""))
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_about".localized,
                                action: #selector(MainMenu.openAbout), keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "mi_quit".localized,
                                action: #selector(MainMenu.terminateApp), keyEquivalent: "q"))
    }

    // MARK: Private Helpers

    internal func addSwitchToPhpMenuItems() {
        var shortcutKey = 1
        for index in (0..<PhpEnv.shared.availablePhpVersions.count).reversed() {

            // Get the short and long version
            let shortVersion = PhpEnv.shared.availablePhpVersions[index]
            let longVersion = PhpEnv.shared.cachedPhpInstallations[shortVersion]!.versionNumber

            let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool
            let versionString = long ? longVersion.toString() : shortVersion

            let action = #selector(MainMenu.switchToPhpVersion(sender:))
            let brew = (shortVersion == PhpEnv.brewPhpVersion) ? "php" : "php@\(shortVersion)"
            let menuItem = PhpMenuItem(
                title: "\("mi_php_switch".localized) \(versionString) (\(brew))",
                action: (shortVersion == PhpEnv.phpInstall.version.short)
                    ? nil
                    : action, keyEquivalent: "\(shortcutKey)"
            )

            menuItem.version = shortVersion
            shortcutKey += 1

            self.addItem(menuItem)
        }
    }

    internal func addExtensionItem(_ phpExtension: PhpExtension, _ shortcutKey: Int) {
        let keyEquivalent = shortcutKey < 9 ? "\(shortcutKey)" : ""

        let menuItem = ExtensionMenuItem(
            title: "\(phpExtension.name) (\(phpExtension.fileNameOnly))",
            action: #selector(MainMenu.toggleExtension),
            keyEquivalent: keyEquivalent
        )

        if menuItem.keyEquivalent != "" {
            menuItem.keyEquivalentModifierMask = [.option]
        }

        menuItem.state = phpExtension.enabled ? .on : .off
        menuItem.phpExtension = phpExtension

        self.addItem(menuItem)
    }
}
