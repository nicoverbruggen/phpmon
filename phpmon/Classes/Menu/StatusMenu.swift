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
        var string = "We are not sure what version of PHP you are running."
        if (App.shared.currentVersion != nil) {
            if (!App.shared.currentVersion!.error) {
                string = "You are running PHP \(App.shared.currentVersion!.long)"
                self.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
            } else {
                // in case of an error show the error message
                self.addItem(NSMenuItem(title: "Oof! It appears your PHP installation is broken...", action: nil, keyEquivalent: ""))
                self.addItem(NSMenuItem(title: "Try running `php -v` in your terminal.", action: nil, keyEquivalent: ""))
                self.addItem(NSMenuItem(title: "You could also try switching to another version.", action: nil, keyEquivalent: ""))
                self.addItem(NSMenuItem(title: "Running `brew reinstall php` (or for the equivalent version) might help.", action: nil, keyEquivalent: ""))
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
                let menuItem = NSMenuItem(title: "Switch to PHP \(version)", action: (version == App.shared.currentVersion?.short) ? nil : action, keyEquivalent: "\(shortcutKey)")
                menuItem.tag = index
                shortcutKey = shortcutKey + 1
                self.addItem(menuItem)
            }
            self.addItem(NSMenuItem.separator())
            self.addItem(NSMenuItem(title: "Active Services", action: nil, keyEquivalent: ""))
            self.addItem(NSMenuItem(title: "Restart php-fpm service", action: #selector(MainMenu.restartPhpFpm), keyEquivalent: "f"))
            self.addItem(NSMenuItem(title: "Restart nginx service", action: #selector(MainMenu.restartNginx), keyEquivalent: "n"))
            self.addItem(NSMenuItem(title: "Force load latest PHP version", action: #selector(MainMenu.forceRestartLatestPhp), keyEquivalent: ""))
        }
        if (App.shared.busy) {
            self.addItem(NSMenuItem(title: "PHP Monitor is busy...", action: nil, keyEquivalent: ""))
        }
    }
    
    public func addPhpConfigurationMenuItems()
    {
        if (App.shared.currentVersion != nil) {
            self.addItem(NSMenuItem(title: "Configuration", action: nil, keyEquivalent: ""))
            self.addItem(NSMenuItem(title: "Valet configuration (.config/valet)", action: #selector(MainMenu.openValetConfigFolder), keyEquivalent: "v"))
            self.addItem(NSMenuItem(title: "PHP configuration file (php.ini)", action: #selector(MainMenu.openActiveConfigFolder), keyEquivalent: "c"))
            self.addItem(NSMenuItem.separator())
            self.addItem(NSMenuItem(title: "Enabled Extensions", action: nil, keyEquivalent: ""))
            self.addXdebugMenuItem()
        }
    }
    
    private func addXdebugMenuItem()
    {
        let xdebugFound = App.shared.currentVersion!.xdebugFound
        if (xdebugFound) {
            let xdebugOn = App.shared.currentVersion!.xdebugEnabled
            let xdebugToggleMenuItem = NSMenuItem(
                title: "Xdebug",
                action: #selector(MainMenu.toggleXdebug), keyEquivalent: "x"
            )
            if (xdebugOn) {
                xdebugToggleMenuItem.state = .on
            }
            self.addItem(xdebugToggleMenuItem)
        } else {
            let disabledItem = NSMenuItem(
                title: "xdebug.so missing",
                action: nil, keyEquivalent: "x"
            )
            disabledItem.isEnabled = false
            self.addItem(disabledItem)
        }
    }
    
}
