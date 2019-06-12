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
    
    let statusItem = NSStatusBar.system.statusItem(
        withLength: 32
    )
    
    var timer: Timer?
    var version: PHPVersion? = nil
    var availablePhpVersions : [String] = []
    var busy: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Start with the ducky
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        // Perform environment boot checks
        DispatchQueue.global(qos: .userInitiated).async {
            Environment.performBootChecks()
        }
        // Check if the correct stuff is installed
        self.availablePhpVersions = Services.detectPhpVersions()
        self.updatePhpVersionInStatusBar()
        // Schedule a request to fetch the PHP version every 15 seconds
        Timer.scheduledTimer(
            timeInterval: 15,
            target: self,
            selector: #selector(updatePhpVersionInStatusBar),
            userInfo: nil,
            repeats: true
        )
    }
    
    func setStatusBarImage(version: String) {
        self.setStatusBar(image: ImageGenerator.generateImageForStatusBar(width: 32.0, text: version))
    }
    
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func updatePhpVersionInStatusBar() {
        self.version = PHPVersion()
        if (self.busy) {
            self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        } else {
            self.setStatusBarImage(version: self.version!.short)
        }
        
        self.updateMenu()
    }
    
    func updateMenu() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let menu = NSMenu()
            var string = "We are not sure what version of PHP you are running."
            if (self.version != nil) {
                string = "You are running PHP \(self.version!.long)"
            }
            menu.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            if (self.availablePhpVersions.count > 0 && !self.busy) {
                for index in (0..<self.availablePhpVersions.count) {
                    let version = self.availablePhpVersions[index]
                    let action = #selector(self.switchToPhpVersion(sender:))
                    let menuItem = NSMenuItem(title: "Switch to PHP \(version)", action: (version == self.version?.short) ? nil : action, keyEquivalent: "\(index + 1)")
                    menuItem.tag = index
                    menu.addItem(menuItem)
                }
                menu.addItem(NSMenuItem.separator())
            }
            if (self.busy) {
                menu.addItem(NSMenuItem(title: "Switching PHP versions...", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }
            menu.addItem(NSMenuItem(title: Services.mysqlIsRunning() ? "You are running MySQL" : "MySQL is not active", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: Services.nginxIsRunning() ? "You are running nginx" : "nginx is not active", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            // menu.addItem(NSMenuItem(title: "About phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            DispatchQueue.main.async {
                self.statusItem.menu = menu
            }
        }
    }
    
    @objc public func switchToPhpVersion(sender: AnyObject) {
        let index = sender.tag!
        let version = self.availablePhpVersions[index]
        self.busy = true
        self.updatePhpVersionInStatusBar()
        self.updateMenu()
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
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

