//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/05/2020.
//  Copyright © 2020 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu : NSMenu {
    
    public func addPhpVersionMenuItems()
    {
        var string = "mi_unsure".localized
        if (App.shared.currentVersion != nil) {
            if (!App.shared.currentVersion!.error) {
                // in case the php version loaded without issue
                string = "\("mi_php_version".localized) \(App.shared.currentVersion!.long)"
                self.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
            } else {
                // in case of an error show the error message
                ["mi_php_broken_1", "mi_php_broken_2",
                 "mi_php_broken_3", "mi_php_broken_4"].forEach { (message) in
                    self.addItem(NSMenuItem(title: message.localized, action: nil, keyEquivalent: ""))
                }
            }
        }
    }
    
    public func addPhpActionMenuItems()
    {
        if (App.shared.availablePhpVersions.count > 0 && !App.shared.busy) {
            var shortcutKey = 1
            for index in (0..<App.shared.availablePhpVersions.count).reversed() {
                let version = App.shared.availablePhpVersions[index]
                let action = #selector(MainMenu.switchToPhpVersion(sender:))
                let brew = (version == App.shared.brewPhpVersion) ? "php" : "php@\(version)"
                let menuItem = PhpMenuItem(title: "\("mi_php_switch".localized) \(version) (\(brew))", action: (version == App.shared.currentVersion?.short) ? nil : action, keyEquivalent: "\(shortcutKey)")
                menuItem.version = version
                shortcutKey = shortcutKey + 1
                self.addItem(menuItem)
            }
            self.addItem(NSMenuItem.separator())
            self.addItem(NSMenuItem(title: "mi_active_services".localized, action: nil, keyEquivalent: ""))
            self.addItem(NSMenuItem(title: "mi_restart_dnsmasq".localized, action: #selector(MainMenu.restartDnsMasq), keyEquivalent: "d"))
            self.addItem(NSMenuItem(title: "mi_restart_php_fpm".localized, action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "p"))
            self.addItem(NSMenuItem(title: "mi_restart_nginx".localized, action: #selector(MainMenu.restartNginx), keyEquivalent: "n"))
            self.addItem(NSMenuItem(title: "mi_restart_all_services".localized, action: #selector(MainMenu.restartAllServices), keyEquivalent: ""))
            
            self.addItem(NSMenuItem.separator())
            self.addItem(NSMenuItem(title: "mi_diagnostics".localized, action: nil, keyEquivalent: ""))
            
            self.addItem(NSMenuItem(title: "mi_force_load_latest".localized, action: #selector(MainMenu.forceRestartLatestPhp), keyEquivalent: ""))
        }
        if (App.shared.busy) {
            self.addItem(NSMenuItem(title: "mi_busy".localized, action: nil, keyEquivalent: ""))
        }
    }
    
    public func addPhpConfigurationMenuItems()
    {
        if (App.shared.currentVersion != nil) {
            self.addItem(NSMenuItem(title: "mi_configuration".localized, action: nil, keyEquivalent: ""))
            self.addItem(NSMenuItem(title: "mi_valet_config".localized, action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
            self.addItem(NSMenuItem(title: "mi_php_config".localized, action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c"))
            self.addItem(NSMenuItem(title: "mi_phpinfo".localized, action: #selector(MainMenu.openPhpInfo), keyEquivalent: "i"))
            self.addItem(NSMenuItem.separator())
            self.addItem(NSMenuItem(title: "mi_enabled_extensions".localized, action: nil, keyEquivalent: ""))
            self.addXdebugMenuItem()
        }
    }
    
    private func addXdebugMenuItem()
    {
        let xdebugFound = App.shared.currentVersion!.xdebugFound
        if (xdebugFound) {
            let xdebugOn = App.shared.currentVersion!.xdebugEnabled
            let xdebugToggleMenuItem = NSMenuItem(
                title: "mi_xdebug".localized,
                action: #selector(MainMenu.toggleXdebug), keyEquivalent: "x"
            )
            if (xdebugOn) {
                xdebugToggleMenuItem.state = .on
            }
            self.addItem(xdebugToggleMenuItem)
        } else {
            let disabledItem = NSMenuItem(
                title: "mi_xdebug_missing".localized,
                action: nil, keyEquivalent: "x"
            )
            disabledItem.isEnabled = false
            self.addItem(disabledItem)
        }
    }
    
}
