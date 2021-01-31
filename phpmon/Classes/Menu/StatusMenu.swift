//
//  MainMenuBuilder.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class StatusMenu : NSMenu {
    public func addPhpVersionMenuItems()
    {
        if (App.shared.currentInstall == nil) {
            return
        }
        
        if (!App.phpInstall!.version.error) {
            // in case the php version loaded without issue
            let string = "\("mi_php_version".localized) \(App.phpInstall!.version.long)"
            self.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
        } else {
            // in case of an error show the error message
            ["mi_php_broken_1", "mi_php_broken_2",
             "mi_php_broken_3", "mi_php_broken_4"].forEach { (message) in
                self.addItem(NSMenuItem(title: message.localized, action: nil, keyEquivalent: ""))
            }
        }
    }
    
    public func addPhpActionMenuItems()
    {
        if App.busy {
            self.addItem(NSMenuItem(title: "mi_busy".localized, action: nil, keyEquivalent: ""))
            return
        }
        if App.shared.availablePhpVersions.count == 0 {
            return
        }
        
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
        
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_active_services".localized, action: nil, keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "mi_restart_dnsmasq".localized, action: #selector(MainMenu.restartDnsMasq), keyEquivalent: "d"))
        self.addItem(NSMenuItem(title: "mi_restart_php_fpm".localized, action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "p"))
        self.addItem(NSMenuItem(title: "mi_restart_nginx".localized, action: #selector(MainMenu.restartNginx), keyEquivalent: "n"))
        self.addItem(NSMenuItem(title: "mi_restart_all_services".localized, action: #selector(MainMenu.restartAllServices), keyEquivalent: "s"))
        
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_diagnostics".localized, action: nil, keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "mi_force_load_latest".localized, action: #selector(MainMenu.forceRestartLatestPhp), keyEquivalent: "f"))
    }
    
    public func addPhpConfigurationMenuItems()
    {
        if App.shared.currentInstall == nil {
            return
        }
 
        self.addItem(NSMenuItem(title: "mi_configuration".localized, action: nil, keyEquivalent: ""))
        self.addItem(NSMenuItem(title: "mi_valet_config".localized, action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
        self.addItem(NSMenuItem(title: "mi_php_config".localized, action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c"))
        self.addItem(NSMenuItem(title: "mi_phpinfo".localized, action: #selector(MainMenu.openPhpInfo), keyEquivalent: "i"))
        
        self.addItem(NSMenuItem.separator())
        self.addItem(NSMenuItem(title: "mi_detected_extensions".localized, action: nil, keyEquivalent: ""))
        
        for phpExtension in App.phpInstall!.extensions {
            self.addExtensionItem(phpExtension)
        }
        
        if (App.phpInstall!.extensions.count == 0) {
            self.addItem(NSMenuItem(title: "mi_no_extensions_detected".localized, action: nil, keyEquivalent: ""))
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
