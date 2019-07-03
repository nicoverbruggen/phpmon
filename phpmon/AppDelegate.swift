//
//  AppDelegate.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Variables
    
    let statusItem = NSStatusBar.system.statusItem(withLength: 32)
    var timer: Timer?
    var version: PhpVersion? = nil
    var availablePhpVersions : [String] = []
    var busy: Bool = false
    
    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Start with the icon
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        // Perform environment boot checks
         DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            BootChecks.perform()
            self.availablePhpVersions = Services.detectPhpVersions()
            print("The following PHP versions were detected:")
            print(self.availablePhpVersions)
            self.updatePhpVersionInStatusBar()
            // Schedule a request to fetch the PHP version every 15 seconds
            Timer.scheduledTimer(
                timeInterval: 15,
                target: self,
                selector: #selector(self.updatePhpVersionInStatusBar),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - UI related
    
    func setStatusBarImage(version: String) {
        self.setStatusBar(image: ImageGenerator.generateImageForStatusBar(width: 32.0, text: version))
    }
    
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }
    
    func updateMenu() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let menu = NSMenu()
            var string = "We are not sure what version of PHP you are running."
            if (self.version != nil) {
                string = "You are running PHP \(self.version!.long)"
            }
            menu.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
            if (self.version != nil) {
                // Actions
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Open php.ini in Finder", action: #selector(self.openActiveConfigFolder), keyEquivalent: ""))
                // menu.addItem(NSMenuItem(title: "Restart PHP \(self.version!.short) service", action: #selector(self.restartPhp), keyEquivalent: ""))
            }
            menu.addItem(NSMenuItem.separator())
            if (self.availablePhpVersions.count > 0 && !self.busy) {
                var shortcutKey = 1
                for index in (0..<self.availablePhpVersions.count).reversed() {
                    let version = self.availablePhpVersions[index]
                    let action = #selector(self.switchToPhpVersion(sender:))
                    let menuItem = NSMenuItem(title: "Switch to PHP \(version)", action: (version == self.version?.short) ? nil : action, keyEquivalent: "\(shortcutKey)")
                    menuItem.tag = index
                    shortcutKey = shortcutKey + 1
                    menu.addItem(menuItem)
                }
                menu.addItem(NSMenuItem.separator())
            }
            if (self.busy) {
                menu.addItem(NSMenuItem(title: "Switching PHP versions...", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
            menu.addItem(NSMenuItem(title: "About phpmon", action: #selector(self.openAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            DispatchQueue.main.async {
                self.statusItem.menu = menu
            }
        }
    }
    
    // MARK: - Callable via Obj-C (#selector)
    
    @objc func updatePhpVersionInStatusBar() {
        self.version = PhpVersion()
        if (self.busy) {
            DispatchQueue.main.async {
                self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
            }
        } else {
            DispatchQueue.main.async {
                self.setStatusBarImage(version: self.version!.short)
            }
        }
        self.updateMenu()
    }
    
    @objc public func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    @objc public func openActiveConfigFolder() {
        Services.openPhpConfigFolder(version: self.version!.short)
    }
    
    @objc public func restartPhp() {
        Services.restartPhp(version: self.version!.short)
    }
    
    @objc public func switchToPhpVersion(sender: AnyObject) {
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        let index = sender.tag!
        let version = self.availablePhpVersions[index]
        self.busy = true
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            // Update the PHP version in the status bar
            self.updatePhpVersionInStatusBar()
            // Update the menu
            self.updateMenu()
            // Switch the PHP version
            Services.switchToPhpVersion(version: version, availableVersions: self.availablePhpVersions)
            // Mark as no longer busy
            self.busy = false
            // Perform UI updates on main thread
            DispatchQueue.main.async {
                self.updatePhpVersionInStatusBar()
                self.updateMenu()
            }
        }
    }
}

