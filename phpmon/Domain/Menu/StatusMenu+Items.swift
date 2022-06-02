//
//  StatusMenu+Items.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension StatusMenu {

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

    func addPresetsMenuItem() {
        if Preferences.custom.presets.isEmpty {
            return
        }

        let presets = NSMenuItem(title: "Configuration Presets", action: nil, keyEquivalent: "")
        let presetsMenu = NSMenu()
        presetsMenu.addItem(NSMenuItem.separator())
        presetsMenu.addItem(HeaderView.asMenuItem(text: "Apply Configuration Presets"))

        for preset in Preferences.custom.presets {
            let presetMenuItem = PresetMenuItem(
                title: preset.getMenuItemText(),
                action: #selector(MainMenu.togglePreset(sender:)),
                keyEquivalent: ""
            )

            if let attributedString = try? NSMutableAttributedString(
                data: preset.getMenuItemText().data(using: .utf8)!,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ) {
                /*
                attributedString.addAttribute(
                    .font,
                    value: NSFont.systemFont(ofSize: 12),
                    range: NSRange(location: 0, length: attributedString.length)
                )
                */
                presetMenuItem.attributedTitle = attributedString
            }

            presetMenuItem.preset = preset
            presetsMenu.addItem(presetMenuItem)
        }

        presetsMenu.addItem(NSMenuItem.separator())
        presetsMenu.addItem(NSMenuItem(
            title: "Revert to Previous Configuration...",
            action: PresetHelper.rollbackPreset != nil
                ? #selector(MainMenu.rollbackPreset)
                : nil,
            keyEquivalent: ""
        ))
        presetsMenu.addItem(NSMenuItem.separator())
        presetsMenu.addItem(NSMenuItem(
            title: "\(Preferences.custom.presets.count) profiles loaded from configuration file",
            action: nil, keyEquivalent: "")
        )
        for item in presetsMenu.items {
            item.target = MainMenu.shared
        }
        self.setSubmenu(presetsMenu, for: presets)
        self.addItem(presets)
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

}
