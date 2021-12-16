//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu : NSMenu {
    func addPhpVersionMenuItems() {
        if App.shared.currentInstall == nil {
            return
        }
        
        if App.phpInstall!.version.error {
            for message in ["mi_php_broken_1", "mi_php_broken_2", "mi_php_broken_3", "mi_php_broken_4"] {
                addItem(NSMenuItem(title: message.localized, action: nil, keyEquivalent: ""))
            }
            return
        }
    
        let phpVersionText = "\("mi_php_version".localized) \(App.phpInstall!.version.long)"
        addItem(HeaderView.asMenuItem(text: phpVersionText))
    }
    
    func addPhpActionMenuItems() {
        if App.busy {
            addItem(NSMenuItem(title: "mi_busy".localized, action: nil, keyEquivalent: ""))
            return
        }
        
        if App.shared.availablePhpVersions.count == 0 {
            return
        }
        
        self.addSwitchToPhpMenuItems()
        self.addItem(NSMenuItem.separator())
    }
    
    func addServicesMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_active_services".localized))
        
        let services = NSMenuItem(title: "mi_manage_services".localized, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_dnsmasq".localized, action: #selector(MainMenu.restartDnsMasq), keyEquivalent: "d"))
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_php_fpm".localized, action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "p"))
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_nginx".localized, action: #selector(MainMenu.restartNginx), keyEquivalent: "n"))
        servicesMenu.addItem(
            NSMenuItem(title: "mi_stop_all_services".localized, action: #selector(MainMenu.stopAllServices), keyEquivalent: "s"),
            withKeyModifier: [.command, .shift])
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_all_services".localized, action: #selector(MainMenu.restartAllServices), keyEquivalent: "s"))
        for item in servicesMenu.items {
            item.target = MainMenu.shared
        }
        self.setSubmenu(servicesMenu, for: services)
        
        self.addForceLoadLatestVersion()
        self.addItem(services)

    }
    
    func addForceLoadLatestVersion() {
        if !App.shared.availablePhpVersions.contains(App.shared.brewPhpVersion) {
            self.addItem(NSMenuItem(
                title: "mi_force_load_latest_unavailable".localized(App.shared.brewPhpVersion),
                action: nil, keyEquivalent: "f"
            ))
        } else {
            self.addItem(NSMenuItem(
                title: "mi_force_load_latest".localized(App.shared.brewPhpVersion),
                action: #selector(MainMenu.forceRestartLatestPhp), keyEquivalent: "f"))
        }
    }
    
    func addValetMenuItems() {
        self.addItem(HeaderView.asMenuItem(text: "mi_valet".localized))
        self.addItem(NSMenuItem(title: "mi_valet_config".localized, action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
        self.addItem(NSMenuItem(title: "mi_sitelist".localized, action: #selector(MainMenu.openSiteList), keyEquivalent: "l"))
        self.addItem(NSMenuItem.separator())
    }
    
    func addPhpConfigurationMenuItems() {
        if App.shared.currentInstall == nil {
            return
        }
        
        // Configuration
        self.addItem(HeaderView.asMenuItem(text: "mi_configuration".localized))
        self.addItem(NSMenuItem(title: "mi_global_composer".localized, action: #selector(MainMenu.openGlobalComposerFolder), keyEquivalent: "g"))
        self.addItem(NSMenuItem(title: "mi_php_config".localized, action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c"))
        self.addItem(NSMenuItem(title: "mi_phpinfo".localized, action: #selector(MainMenu.openPhpInfo), keyEquivalent: "i"))
        
        if (App.shared.busy) {
            return
        }
        
        let stats = App.phpInstall!.limits
        
        // Stats
        self.addItem(NSMenuItem.separator())
        self.addItem(StatsView.asMenuItem(
            memory: stats!.memory_limit,
            post: stats!.post_max_size,
            upload: stats!.upload_max_filesize)
        )
        
        // Extensions
        self.addItem(NSMenuItem.separator())
        self.addItem(HeaderView.asMenuItem(text: "mi_detected_extensions".localized))
        
        if (App.phpInstall!.extensions.count == 0) {
            self.addItem(NSMenuItem(title: "mi_no_extensions_detected".localized, action: nil, keyEquivalent: ""))
        }
        
        var shortcutKey = 1
        for phpExtension in App.phpInstall!.extensions {
            self.addExtensionItem(phpExtension, shortcutKey)
            shortcutKey += 1
        }
        
        self.addItem(NSMenuItem.separator())
        
        self.addItem(NSMenuItem(title: "mi_php_refresh".localized, action: #selector(MainMenu.reloadPhpMonitorMenu), keyEquivalent: "r"))
    }
    
    private func addSwitchToPhpMenuItems() {
        var shortcutKey = 1
        for index in (0..<App.shared.availablePhpVersions.count).reversed() {
            
            // Get the short and long version
            let shortVersion = App.shared.availablePhpVersions[index]
            let longVersion = App.shared.cachedPhpInstallations[shortVersion]!.longVersion
            
            let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool
            let versionString = long ? longVersion : shortVersion
            
            let action = #selector(MainMenu.switchToPhpVersion(sender:))
            let brew = (shortVersion == App.shared.brewPhpVersion) ? "php" : "php@\(shortVersion)"
            let menuItem = PhpMenuItem(
                title: "\("mi_php_switch".localized) \(versionString) (\(brew))",
                action: (shortVersion == App.phpInstall?.version.short) ? nil : action, keyEquivalent: "\(shortcutKey)"
            )
            
            menuItem.version = shortVersion
            shortcutKey = shortcutKey + 1
            
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

// MARK: - In order to store extra data in each item, NSMenuItem is subclassed

class PhpMenuItem: NSMenuItem {
    var version: String = ""
}

class ExtensionMenuItem: NSMenuItem {
    var phpExtension: PhpExtension? = nil
}

class EditorMenuItem: NSMenuItem {
    var editor: Application? = nil
}
