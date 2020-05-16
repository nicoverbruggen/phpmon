//
//  MainMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/07/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSWindowDelegate {

    static let shared = MainMenu()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // MARK: - UI related
    
    public func startup() {
        // Start with the icon
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        // Perform environment boot checks
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            Startup.checkEnvironment()
            App.shared.availablePhpVersions = Actions.detectPhpVersions()
            self.updatePhpVersionInStatusBar()
            // Schedule a request to fetch the PHP version every 60 seconds
            DispatchQueue.main.async {
                App.shared.timer = Timer.scheduledTimer(
                    timeInterval: 60,
                    target: self,
                    selector: #selector(self.updatePhpVersionInStatusBar),
                    userInfo: nil,
                    repeats: true
                )
            }
        }
    }
    
    public func update() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let menu = NSMenu()
            var string = "We are not sure what version of PHP you are running."
            if (App.shared.currentVersion != nil) {
                if (!App.shared.currentVersion!.error) {
                    string = "You are running PHP \(App.shared.currentVersion!.long)"
                    menu.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
                } else {
                    // in case of an error show the error message
                    menu.addItem(NSMenuItem(title: "Oof! It appears your PHP installation is broken...", action: nil, keyEquivalent: ""))
                    menu.addItem(NSMenuItem(title: "Try running `php -v` in your terminal.", action: nil, keyEquivalent: ""))
                    menu.addItem(NSMenuItem(title: "You could also try switching to another version.", action: nil, keyEquivalent: ""))
                    menu.addItem(NSMenuItem(title: "Running `brew reinstall php` (or for the equivalent version) might help.", action: nil, keyEquivalent: ""))
                }
            }
            
            menu.addItem(NSMenuItem.separator())
            if (App.shared.availablePhpVersions.count > 0 && !App.shared.busy) {
                var shortcutKey = 1
                for index in (0..<App.shared.availablePhpVersions.count).reversed() {
                    let version = App.shared.availablePhpVersions[index]
                    let action = #selector(self.switchToPhpVersion(sender:))
                    let menuItem = NSMenuItem(title: "Switch to PHP \(version)", action: (version == App.shared.currentVersion?.short) ? nil : action, keyEquivalent: "\(shortcutKey)")
                    menuItem.tag = index
                    shortcutKey = shortcutKey + 1
                    menu.addItem(menuItem)
                }
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Active Services", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Restart php-fpm service", action: #selector(self.restartPhpFpm), keyEquivalent: "f"))
                menu.addItem(NSMenuItem(title: "Restart nginx service", action: #selector(self.restartNginx), keyEquivalent: "n"))
                menu.addItem(NSMenuItem(title: "Force load latest PHP version", action: #selector(self.forceRestartLatestPhp), keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
            if (App.shared.busy) {
                menu.addItem(NSMenuItem(title: "PHP Monitor is busy...", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
            if (App.shared.currentVersion != nil) {
                menu.addItem(NSMenuItem(title: "Configuration", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Valet configuration (.config/valet)", action: #selector(self.openValetConfigFolder), keyEquivalent: "v"))
                menu.addItem(NSMenuItem(title: "PHP configuration file (php.ini)", action: #selector(self.openActiveConfigFolder), keyEquivalent: "c"))
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Enabled Extensions", action: nil, keyEquivalent: ""))
                let xdebugFound = App.shared.currentVersion!.xdebugFound
                if (xdebugFound) {
                    let xdebugOn = App.shared.currentVersion!.xdebugEnabled
                    let xdebugToggleMenuItem = NSMenuItem(
                        title: "Xdebug",
                        action: #selector(self.toggleXdebug), keyEquivalent: "x"
                    )
                    if (xdebugOn) {
                        xdebugToggleMenuItem.state = .on
                    }
                    menu.addItem(xdebugToggleMenuItem)
                } else {
                    let disabledItem = NSMenuItem(
                        title: "xdebug.so missing",
                        action: nil, keyEquivalent: "x"
                    )
                    disabledItem.isEnabled = false
                    menu.addItem(disabledItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "About PHP Monitor", action: #selector(self.openAbout), keyEquivalent: ""))
            menu.items.forEach({ (item) in
                item.target = self
            })
            menu.addItem(NSMenuItem(title: "Quit PHP Monitor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            DispatchQueue.main.async {
                self.statusItem.menu = menu
            }
        }
    }
    
    func setStatusBarImage(version: String) {
        self.setStatusBar(
            image: MenuBarImageGenerator.textToImage(
                text: version
            )
        )
    }
    
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }
    
    // MARK: - Invokable Logic
    
    private func waitAndExecute(_ execute: @escaping () -> Void, _ completion: @escaping () -> Void = {})
    {
        App.shared.busy = true
        self.setBusyImage()
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            self.update()
            execute()
            App.shared.busy = false
            DispatchQueue.main.async {
                self.updatePhpVersionInStatusBar()
                self.update()
                completion()
            }
        }
    }
    
    // MARK: - Callable via Obj-C (#selector)
    
    @objc func updatePhpVersionInStatusBar() {
        App.shared.currentVersion = PhpVersion()
        if (App.shared.busy) {
            DispatchQueue.main.async {
                self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
            }
        } else {
            DispatchQueue.main.async {
                self.setStatusBarImage(version: App.shared.currentVersion!.short)
            }
        }
        self.update()
    }
    
    @objc func setBusyImage() {
        DispatchQueue.main.async {
            self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        }
    }
    
    @objc public func restartPhpFpm() {
        self.waitAndExecute({
            Actions.restartPhpFpm()
        })
    }
    
    @objc public func restartNginx() {
        self.waitAndExecute({
            Actions.restartNginx()
        })
    }
    
    @objc public func toggleXdebug() {
        self.waitAndExecute({
            Actions.toggleXdebug()
        })
    }
    
    @objc public func forceRestartLatestPhp() {
        Alert.present(
            messageText: "alert.force_reload.title".localized,
            informativeText: "alert.force_reload.info".localized
        )
        self.waitAndExecute({ Actions.fixMyPhp() }, {
            Alert.present(
                messageText: "alert.force_reload_done.title".localized,
                informativeText: "alert.force_reload_done.info".localized
            )
        })
    }
    
    @objc public func openActiveConfigFolder() {
        if (App.shared.currentVersion!.error) {
            // php version was not identified
            Actions.openGenericPhpConfigFolder()
        } else {
            // php version was identified
            Actions.openPhpConfigFolder(version: App.shared.currentVersion!.short)
        }
        
    }
    
    @objc public func openValetConfigFolder() {
        Actions.openValetConfigFolder()
    }
    
    @objc public func switchToPhpVersion(sender: AnyObject) {
        self.setBusyImage()
        let index = sender.tag!
        let version = App.shared.availablePhpVersions[index]
        App.shared.busy = true
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            // Update the PHP version in the status bar
            self.updatePhpVersionInStatusBar()
            // Update the menu
            self.update()
            // Switch the PHP version
            Actions.switchToPhpVersion(
                version: version,
                availableVersions: App.shared.availablePhpVersions
            )
            // Mark as no longer busy
            App.shared.busy = false
            // Perform UI updates on main thread
            DispatchQueue.main.async {
                self.updatePhpVersionInStatusBar()
                self.update()
            }
        }
    }
    
    @objc public func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    func windowWillClose(_ notification: Notification) {
        App.shared.windowController = nil
        Shell.user.delegate = nil
    }
}
