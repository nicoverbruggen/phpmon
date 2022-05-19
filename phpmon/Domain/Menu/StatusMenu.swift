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

        self.addFirstAidAndServicesMenuItems()
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

    // MARK: Remaining Menu Items

    func addConfigurationMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_configuration".localized))
        self.addItem(
            NSMenuItem(title: "mi_php_config".localized,
                       action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c")
        )
        self.addItem(
            NSMenuItem(title: "mi_phpinfo".localized, action: #selector(MainMenu.openPhpInfo), keyEquivalent: "i")
        )
    }

    func addComposerMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_composer".localized))
        self.addItem(
            NSMenuItem(title: "mi_global_composer".localized,
                       action: #selector(MainMenu.openGlobalComposerFolder), keyEquivalent: "g")
        )

        let composerMenuItem = NSMenuItem(
            title: "mi_update_global_composer".localized,
            action: PhpEnv.shared.isBusy ? nil : #selector(MainMenu.updateGlobalComposerDependencies),
            keyEquivalent: "g"
        )
        composerMenuItem.keyEquivalentModifierMask = .shift

        self.addItem(composerMenuItem)
    }

    func addStatsMenuItem() {
        guard let stats = PhpEnv.phpInstall.limits else { return }

        self.addItem(StatsView.asMenuItem(
            memory: stats.memory_limit,
            post: stats.post_max_size,
            upload: stats.upload_max_filesize)
        )
    }

    func addExtensionsMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_detected_extensions".localized))

        if PhpEnv.phpInstall.extensions.isEmpty {
            self.addItem(NSMenuItem(title: "mi_no_extensions_detected".localized, action: nil, keyEquivalent: ""))
        }

        var shortcutKey = 1
        for phpExtension in PhpEnv.phpInstall.extensions {
            self.addExtensionItem(phpExtension, shortcutKey)
            shortcutKey += 1
        }
    }

    func addXdebugMenuItem() {
        if !Xdebug.enabled {
            return
        }

        let xdebugSwitch = NSMenuItem(
            title: "mi_xdebug_mode".localized,
            action: nil,
            keyEquivalent: ""
        )
        let xdebugModesMenu = NSMenu()
        let activeModes = Xdebug.activeModes

        xdebugModesMenu.addItem(HeaderView.asMenuItem(text: "Available Modes"))

        for mode in Xdebug.modes {
            let item = XdebugMenuItem(
                title: mode,
                action: #selector(MainMenu.toggleXdebugMode(sender:)),
                keyEquivalent: ""
            )

            item.state = activeModes.contains(mode) ? .on : .off
            item.mode = mode
            xdebugModesMenu.addItem(item)
        }

        xdebugModesMenu.addItem(HeaderView.asMenuItem(text: "Actions"))
        xdebugModesMenu.addItem(
            withTitle: "Disable All",
            action: #selector(MainMenu.disableAllXdebugModes),
            keyEquivalent: ""
        )

        for item in xdebugModesMenu.items {
            item.target = MainMenu.shared
        }

        self.setSubmenu(xdebugModesMenu, for: xdebugSwitch)
        self.addItem(xdebugSwitch)
    }

    func addFirstAidAndServicesMenuItems() {
        let services = NSMenuItem(title: "mi_other".localized, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()

        let fixMyValetMenuItem = NSMenuItem(
            title: "mi_fix_my_valet".localized(PhpEnv.brewPhpVersion),
            action: #selector(MainMenu.fixMyValet), keyEquivalent: ""
        )
        fixMyValetMenuItem.toolTip = "mi_fix_my_valet_tooltip".localized
        servicesMenu.addItem(fixMyValetMenuItem)

        let fixHomebrewMenuItem = NSMenuItem(
            title: "mi_fix_brew_permissions".localized(),
            action: #selector(MainMenu.fixHomebrewPermissions), keyEquivalent: ""
        )
        fixHomebrewMenuItem.toolTip = "mi_fix_brew_permissions_tooltip".localized
        servicesMenu.addItem(fixHomebrewMenuItem)

        servicesMenu.addItem(NSMenuItem.separator())
        servicesMenu.addItem(HeaderView.asMenuItem(text: "mi_services".localized))

        servicesMenu.addItem(
            NSMenuItem(title: "mi_restart_dnsmasq".localized,
                       action: #selector(MainMenu.restartDnsMasq), keyEquivalent: "d")
        )
        servicesMenu.addItem(
            NSMenuItem(title: "mi_restart_php_fpm".localized,
                       action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "p")
        )
        servicesMenu.addItem(
            NSMenuItem(title: "mi_restart_nginx".localized,
                       action: #selector(MainMenu.restartNginx), keyEquivalent: "n")
        )
        servicesMenu.addItem(
            NSMenuItem(title: "mi_restart_all_services".localized,
                       action: #selector(MainMenu.restartAllServices), keyEquivalent: "s")
        )
        servicesMenu.addItem(
            NSMenuItem(title: "mi_stop_all_services".localized,
                       action: #selector(MainMenu.stopAllServices), keyEquivalent: "s"),
            withKeyModifier: [.command, .shift]
        )

        servicesMenu.addItem(NSMenuItem.separator())
        servicesMenu.addItem(HeaderView.asMenuItem(text: "mi_manual_actions".localized))

        servicesMenu.addItem(
            NSMenuItem(title: "mi_php_refresh".localized,
                       action: #selector(MainMenu.reloadPhpMonitorMenuInForeground), keyEquivalent: "r")
        )

        for item in servicesMenu.items {
            item.target = MainMenu.shared
        }

        self.setSubmenu(servicesMenu, for: services)
        self.addItem(services)
    }

    // MARK: Private Helpers

    private func addSwitchToPhpMenuItems() {
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

    private func addExtensionItem(_ phpExtension: PhpExtension, _ shortcutKey: Int) {
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

// MARK: - NSMenuItem subclasses

class PhpMenuItem: NSMenuItem {
    var version: String = ""
}

class XdebugMenuItem: NSMenuItem {
    var mode: String = ""
}

class ExtensionMenuItem: NSMenuItem {
    var phpExtension: PhpExtension?
}

class EditorMenuItem: NSMenuItem {
    var editor: Application?
}
