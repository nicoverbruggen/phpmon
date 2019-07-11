//
//  MainMenu.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/07/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSWindowDelegate {

    static let shared = MainMenu()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: 32)
    
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
                string = "You are running PHP \(App.shared.currentVersion!.long)"
            }
            menu.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
            if (App.shared.currentVersion != nil) {
                // Actions
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "PHP configuration file (php.ini)", action: #selector(self.openActiveConfigFolder), keyEquivalent: ""))
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
            }
            if (App.shared.busy) {
                menu.addItem(NSMenuItem(title: "Switching PHP versions...", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
            menu.addItem(NSMenuItem(title: "View Shell Output", action: #selector(self.openOutput), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "About phpmon", action: #selector(self.openAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            menu.items.forEach({ (item) in
                item.target = self
            })
            DispatchQueue.main.async {
                self.statusItem.menu = menu
            }
        }
    }
    
    func setStatusBarImage(version: String) {
        self.setStatusBar(
            image: MenuBarImageGenerator.textToImage(
                width: 32.0,
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
    
    // MARK: - Callable via Obj-C (#selector)
    
    @objc func openOutput() {
        LogViewController.show(delegate: self)
    }
    
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
    
    @objc public func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    @objc public func openActiveConfigFolder() {
        Actions.openPhpConfigFolder(version: App.shared.currentVersion!.short)
    }
    
    @objc public func switchToPhpVersion(sender: AnyObject) {
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
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
    
    func windowWillClose(_ notification: Notification) {
        App.shared.windowController = nil
        Shell.shared.delegate = nil
    }
}
