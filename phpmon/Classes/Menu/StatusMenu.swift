//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu : NSMenu {
    public func addPhpVersionMenuItems() {
        if App.shared.currentInstall == nil {
            return
        }
        
        if App.phpInstall!.version.error {
            for message in ["mi_php_broken_1", "mi_php_broken_2", "mi_php_broken_3", "mi_php_broken_4"] {
                self.addItem(NSMenuItem(title: message.localized, action: nil, keyEquivalent: ""))
            }
            return
        }
        
        let string = "\("mi_php_version".localized) \(App.phpInstall!.version.long)"
        self.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
    }
    
    public func addPhpActionMenuItems() {
        if App.busy {
            self.addItem(NSMenuItem(title: "mi_busy".localized, action: nil, keyEquivalent: ""))
            return
        }
        
        if App.shared.availablePhpVersions.count == 0 {
            return
        }
        
        self.addSwitchToPhpMenuItems()
        self.addItem(NSMenuItem.separator())
        self.addServicesMenuItems()
    }
    
    private func addSwitchToPhpMenuItems() {
        var shortcutKey = 1
        for index in (0..<App.shared.availablePhpVersions.count).reversed() {
            let version = App.shared.availablePhpVersions[index]
            let action = #selector(MainMenu.switchToPhpVersion(sender:))
            let brew = (version == App.shared.brewPhpVersion) ? "php" : "php@\(version)"
            let menuItem = PhpMenuItem(
                title: "\("mi_php_switch".localized) \(version) (\(brew))",
                action: (version == App.phpInstall?.version.short) ? nil : action, keyEquivalent: "\(shortcutKey)"
            )
            menuItem.version = version
            shortcutKey = shortcutKey + 1
            self.addItem(menuItem)
        }
    }
    
    private func addServicesMenuItems() {
        self.addItem(NSMenuItem(title: "mi_active_services".localized, action: nil, keyEquivalent: ""))
        
        let services = NSMenuItem(title: "mi_restart_specific".localized, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_dnsmasq".localized, action: #selector(MainMenu.restartDnsMasq), keyEquivalent: "d"))
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_php_fpm".localized, action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "p"))
        servicesMenu.addItem(NSMenuItem(title: "mi_restart_nginx".localized, action: #selector(MainMenu.restartNginx), keyEquivalent: "n"))
        for item in servicesMenu.items {
            item.target = MainMenu.shared
        }
        self.setSubmenu(servicesMenu, for: services)
        
        self.addItem(NSMenuItem(title: "mi_force_load_latest".localized, action: #selector(MainMenu.forceRestartLatestPhp), keyEquivalent: "f"))
        self.addItem(services)
        self.addItem(NSMenuItem(title: "mi_restart_all_services".localized, action: #selector(MainMenu.restartAllServices), keyEquivalent: "s"))
    }
    
    public func addPhpConfigurationMenuItems() {
        if App.shared.currentInstall == nil {
            return
        }
        
        // Configuration
        self.addItem(NSMenuItem(title: "mi_configuration".localized, action: nil, keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "mi_valet_config".localized, action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
        self.addItem(NSMenuItem(title: "mi_php_config".localized, action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c"))
        self.addItem(NSMenuItem(title: "mi_phpinfo".localized, action: #selector(MainMenu.openPhpInfo), keyEquivalent: "i"))
        
        // Limits
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_limits".localized, action: nil, keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "\("mi_memory_limit".localized): \(App.phpInstall!.configuration.memory_limit)", action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "\("mi_post_max_size".localized): \(App.phpInstall!.configuration.post_max_size)", action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "\("mi_upload_max_filesize".localized): \(App.phpInstall!.configuration.upload_max_filesize)", action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: ""))
        
        // Extensions
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_detected_extensions".localized, action: nil, keyEquivalent: ""))
        
        if (App.phpInstall!.extensions.count == 0) {
            self.addItem(NSMenuItem(title: "mi_no_extensions_detected".localized, action: nil, keyEquivalent: ""))
        }
        
        for phpExtension in App.phpInstall!.extensions {
            self.addExtensionItem(phpExtension)
        }
    }
    
    private func addExtensionItem(_ phpExtension: PhpExtension) {
        let menuItem = ExtensionMenuItem(
            title: "\(phpExtension.name.capitalized) (php.ini)",
            action: #selector(MainMenu.toggleExtension), keyEquivalent: ""
        )
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
