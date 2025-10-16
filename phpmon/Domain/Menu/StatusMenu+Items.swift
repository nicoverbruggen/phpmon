//
//  StatusMenu+Items.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

// MARK: - PHP Version

extension StatusMenu {

    @MainActor func addPhpVersionMenuItems() {
        if container.phpEnvs.phpInstall == nil {
            addItem(HeaderView.asMenuItem(text: "⚠️ " + "mi_no_php_linked".localized, minimumWidth: 280))
            addItems([
                NSMenuItem.separator(),
                NSMenuItem(title: "mi_fix_php_link".localized, action: #selector(MainMenu.linkPhpBinary)),
                NSMenuItem(title: "mi_no_php_linked_explain".localized, action: #selector(MainMenu.displayUnlinkedInfo))
            ])
            return
        }

        if container.phpEnvs.phpInstall!.hasErrorState {
            let brokenMenuItems = ["mi_php_broken_1", "mi_php_broken_2", "mi_php_broken_3", "mi_php_broken_4"]
            return addItems(brokenMenuItems.map { NSMenuItem(title: $0.localized) })
        }

        addItem(HeaderView.asMenuItem(
            text: "\("mi_php_version".localized) \(container.phpEnvs.phpInstall!.version.long)",
            minimumWidth: 280 // this ensures the menu is at least wide enough not to cause clipping
        ))
    }

    @MainActor func addPhpActionMenuItems() {
        if App.shared.container.phpEnvs.isBusy {
            addItem(NSMenuItem(title: "mi_busy".localized))
            return
        }

        if App.shared.container.phpEnvs.availablePhpVersions.isEmpty
            && App.shared.container.phpEnvs.incompatiblePhpVersions.isEmpty {
            return
        }

        if App.shared.container.phpEnvs.currentInstall == nil {
            return
        }

        addSwitchToPhpMenuItems()

        self.addItem(NSMenuItem.separator())
    }

    @MainActor func addServicesManagerMenuItem() {
        if App.shared.container.phpEnvs.isBusy {
            return
        }

        addItems([
            ServicesView.asMenuItem(),
            NSMenuItem.separator()
        ])
    }

    @MainActor func addSwitchToPhpMenuItems() {
        var shortcutKey = 1
        for index in (0..<App.shared.container.phpEnvs.availablePhpVersions.count) {
            // Get the short and long version
            let shortVersion = App.shared.container.phpEnvs.availablePhpVersions[index]
            let longVersion = App.shared.container.phpEnvs.cachedPhpInstallations[shortVersion]!.versionNumber

            let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool
            let versionString = long ? longVersion.text : shortVersion

            let action = #selector(MainMenu.switchToPhpVersion(sender:))
            let brew = (shortVersion == PhpEnvironments.brewPhpAlias) ? "php" : "php@\(shortVersion)"

            let isActive = (shortVersion == container.phpEnvs.phpInstall?.version.short)

            let menuItem = PhpMenuItem(
                title: "\("mi_php_switch".localized) \(versionString) (\(brew))",
                action: isActive ? nil : action, keyEquivalent: "\(shortcutKey)",
                systemImage: isActive ? "checkmark.square.fill" : "square.dotted"
            )

            menuItem.version = shortVersion
            shortcutKey += 1

            addItem(menuItem)
        }

        if !App.shared.container.phpEnvs.incompatiblePhpVersions.isEmpty {
            addItem(NSMenuItem.separator())
            addItem(NSMenuItem(
                title: "⚠️ " + "mi_php_unsupported".localized(
                    "\(App.shared.container.phpEnvs.incompatiblePhpVersions.count)"
                ),
                action: #selector(MainMenu.showIncompatiblePhpVersionsAlert)
            ))
        }
    }

    @MainActor func addPreferencesMenuItems() {

        addItems([
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_preferences".localized,
                       action: #selector(MainMenu.openPrefs),
                       keyEquivalent: ",",
                       systemImage: "gear"
            ),
            NSMenuItem(title: "mi_check_for_updates".localized,
                       action: #selector(MainMenu.checkForUpdates),
                       systemImage: "arrow.clockwise.circle"
            )
        ])
    }

    @MainActor func addCoreMenuItems() {
        addItems([
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_about".localized,
                       action: #selector(MainMenu.openAbout)),
            NSMenuItem(title: "mi_quit".localized,
                       action: #selector(MainMenu.terminateApp), keyEquivalent: "q")
        ])
    }

    // MARK: - Valet

    @MainActor func addValetMenuItems() {
        addItems([
            HeaderView.asMenuItem(text: "mi_valet".localized),
            NSMenuItem(title: "mi_valet_config".localized,
                       action: #selector(MainMenu.openValetConfigFolder),
                       keyEquivalent: "v",
                       systemImage: "folder.badge.gearshape"),
            NSMenuItem(title: "mi_domain_list".localized,
                       action: #selector(MainMenu.openDomainList),
                       keyEquivalent: "l",
                       systemImage: "globe"),
            NSMenuItem.separator()
        ])
    }

    // MARK: - PHP Configuration

    @MainActor func addConfigurationMenuItems() {
        addItems([
            HeaderView.asMenuItem(text: "mi_configuration".localized),
            NSMenuItem(title: "mi_php_version_manager".localized,
                       action: #selector(MainMenu.openPhpVersionManager),
                       keyEquivalent: "m",
                       systemImage: "cpu.fill"),
            NSMenuItem(title: "mi_php_ext_manager".localized,
                       action: #selector(MainMenu.openPhpExtensionManager),
                       keyEquivalent: "e",
                       systemImage: "puzzlepiece.extension"),
            NSMenuItem(title: "mi_php_config".localized,
                       action: #selector(MainMenu.openActiveConfigFolder),
                       keyEquivalent: "c",
                       systemImage: "folder.badge.gearshape"),
            NSMenuItem(title: "mi_phpmon_config".localized,
                       action: #selector(MainMenu.openPhpMonitorConfigurationFile),
                       keyEquivalent: "y",
                       systemImage: "folder.badge.person.crop"),
            NSMenuItem(title: "mi_phpinfo".localized,
                       action: #selector(MainMenu.openPhpInfo),
                       keyEquivalent: "i",
                       systemImage: "info.circle.fill")
        ])
    }

    // MARK: - Composer

    @MainActor func addComposerMenuItems() {
        addItems([
            HeaderView.asMenuItem(text: "mi_composer".localized),
            NSMenuItem(
                title: "mi_global_composer".localized,
                action: #selector(MainMenu.openGlobalComposerFolder),
                keyEquivalent: "g",
                systemImage: "plus.rectangle.on.folder"
            ),
            NSMenuItem(
                title: "mi_update_global_composer".localized,
                action: App.shared.container.phpEnvs.isBusy
                ? nil
                : #selector(MainMenu.updateGlobalComposerDependencies),
                keyEquivalent: "g",
                keyModifier: [.shift],
                systemImage: "arrow.down.to.line.square"
            )
        ])
    }

    // MARK: - Stats

    @MainActor func addStatsMenuItem() {
        guard let install = container.phpEnvs.phpInstall else {
            Log.info("Not showing stats menu item if no PHP version is linked.")
            return
        }

        guard let stats = install.limits else { return }

        addItem(StatsView.asMenuItem(
            memory: stats.memory_limit,
            post: stats.post_max_size,
            upload: stats.upload_max_filesize)
        )
    }

    // MARK: - Extensions

    @MainActor func addExtensionsMenuItems() {
        guard let install = container.phpEnvs.phpInstall else {
            Log.info("Not showing extensions menu items if no PHP version is linked.")
            return
        }

        addItem(HeaderView.asMenuItem(text: "mi_detected_extensions".localized))

        if install.extensions.isEmpty {
            addItem(NSMenuItem(title: "mi_no_extensions_detected".localized, action: nil, keyEquivalent: ""))
        }

        var shortcutKey = 1
        for phpExtension in install.extensions {
            addExtensionItem(phpExtension, shortcutKey)
            shortcutKey += 1
        }
    }

    // MARK: - Presets

    @MainActor func addPresetsMenuItem() {
        guard let presets = Preferences.custom.presets else {
            addEmptyPresetHelp()
            return
        }

        if presets.isEmpty {
            addEmptyPresetHelp()
            return
        }

        addLoadedPresets()
    }

    @MainActor private func addEmptyPresetHelp() {
        addItem(NSMenuItem(title: "mi_presets_title".localized, systemImage: "puzzlepiece.fill", submenu: [
            NSMenuItem(title: "mi_no_presets".localized),
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_set_up_presets".localized,
                       action: #selector(MainMenu.showPresetHelp))
        ], target: MainMenu.shared))
    }

    @MainActor private func addLoadedPresets() {
        addItem(NSMenuItem(title: "mi_presets_title".localized, systemImage: "puzzlepiece.fill", submenu: [
            NSMenuItem.separator(),
            HeaderView.asMenuItem(text: "mi_apply_presets_title".localized)
        ] + PresetMenuItem.getAll() + [
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_revert_to_prev_config".localized,
                       action: PresetHelper.rollbackPreset != nil ? #selector(MainMenu.rollbackPreset) : nil),
            NSMenuItem.separator(),
            NSMenuItem(title: "mi_profiles_loaded".localized(Preferences.custom.presets!.count))
        ], target: MainMenu.shared))
    }

    // MARK: - Xdebug

    @MainActor func addXdebugMenuItem() {
        let xdebug = Xdebug()

        if !xdebug.enabled {
            addItem(NSMenuItem.separator())
            return
        }

        addItems([
            NSMenuItem(title: "mi_xdebug_mode".localized, submenu: [
                HeaderView.asMenuItem(text: "mi_xdebug_available_modes".localized)
            ] + xdebug.asMenuItems() + [
                HeaderView.asMenuItem(text: "mi_xdebug_actions".localized),
                NSMenuItem(title: "mi_xdebug_disable_all".localized,
                           action: #selector(MainMenu.disableAllXdebugModes))
            ], target: MainMenu.shared),
            NSMenuItem.separator()
        ], target: MainMenu.shared)
    }

    // MARK: - PHP Doctor

    @MainActor func addPhpDoctorMenuItem() {
        if !Preferences.isEnabled(.showPhpDoctorSuggestions) ||
            !App.shared.container.warningManager.hasWarnings() {
            return
        }

        addItems([
            HeaderView.asMenuItem(text: "mi_php_doctor".localized),
            NSMenuItem(title: "mi_recommendations_count".localized(App.shared.container.warningManager.warnings.count)),
            NSMenuItem(title: "mi_view_recommendations".localized, action: #selector(MainMenu.openWarnings)),
            NSMenuItem.separator()
        ])
    }

    // MARK: - First Aid & Services

    @MainActor func addFirstAidAndServicesMenuItems() {
        let services = NSMenuItem(title: "mi_other".localized, systemImage: "cross.case")

        var items: [NSMenuItem] = [
            // FIRST AID
            HeaderView.asMenuItem(text: "mi_first_aid".localized),
            NSMenuItem(title: "mi_view_onboarding".localized, action: #selector(MainMenu.showWelcomeTour)),
            NSMenuItem(title: "mi_fa_php_doctor".localized, action: #selector(MainMenu.openWarnings))
        ]

        if Valet.installed {
            items.append(contentsOf: [
                NSMenuItem.separator(),
                HeaderView.asMenuItem(text: "Laravel Valet"),
                NSMenuItem(title: "mi_fix_my_valet".localized(PhpEnvironments.brewPhpAlias),
                           action: #selector(MainMenu.fixMyValet),
                           toolTip: "mi_fix_my_valet_tooltip".localized),
                NSMenuItem(title: "mi_fix_brew_permissions".localized(),
                           action: #selector(MainMenu.fixHomebrewPermissions),
                           toolTip: "mi_fix_brew_permissions_tooltip".localized),
               NSMenuItem.separator(),

                // SERVICES
                HeaderView.asMenuItem(text: "mi_services".localized),
                NSMenuItem(title: "mi_restart_dnsmasq".localized, action: #selector(MainMenu.restartDnsMasq),
                           keyEquivalent: "d"),
                NSMenuItem(title: "mi_restart_php_fpm".localized, action: #selector(MainMenu.restartPhpFpm),
                           keyEquivalent: "p"),
                NSMenuItem(title: "mi_restart_nginx".localized, action: #selector(MainMenu.restartNginx),
                           keyEquivalent: "n"),
                NSMenuItem(title: "mi_restart_valet_services".localized,
                           action: #selector(MainMenu.restartValetServices),
                           keyEquivalent: "s"),
                NSMenuItem(title: "mi_stop_valet_services".localized, action: #selector(MainMenu.stopValetServices),
                           keyEquivalent: "s",
                           keyModifier: [.command, .shift]),
                NSMenuItem.separator()
            ])
        } else {
            items.append(NSMenuItem.separator())
        }

        items.append(contentsOf: [
            // MANUAL ACTIONS
            HeaderView.asMenuItem(text: "mi_manual_actions".localized),
            NSMenuItem(title: "mi_php_refresh".localized,
                       action: #selector(MainMenu.reloadPhpMonitorMenuInForeground),
                       keyEquivalent: "r")
        ])

        let servicesMenu = NSMenu()
        servicesMenu.addItems(items, target: MainMenu.shared)
        setSubmenu(servicesMenu, for: services)
        addItem(services)
    }

    // MARK: - Other helper methods to generate menu items

    @MainActor func addExtensionItem(_ phpExtension: PhpExtension, _ shortcutKey: Int) {
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

        addItem(menuItem)
    }
}
