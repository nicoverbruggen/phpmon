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
    
    var timer: Timer?
    var version: PhpVersionExtractor? = nil
    var availablePhpVersions : [String] = []
    var busy: Bool = false

    let statusItem = NSStatusBar.system.statusItem(
        withLength: 32
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        print(Shell.execute(command: "which php"))
        print(Shell.execute(command: "echo $HOME"))
        print(Shell.execute(command: "which valet"))
        
        self.availablePhpVersions = Services.detectPhpVersions()
        self.setStatusBarImage(version: "???")
        self.updatePhpVersionInStatusBar()
        // Schedule a request to fetch the PHP version every 15 seconds
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(updatePhpVersionInStatusBar), userInfo: nil, repeats: true)
    }
    
    func setStatusBarImage(version: String) {
        if let button = statusItem.button {
            let image = ImageGenerator.generateImageForStatusBar(width: 32.0, text: version)
            image.isTemplate = true
            button.image = image
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func updatePhpVersionInStatusBar() {
        self.version = PhpVersionExtractor()
        self.setStatusBarImage(version: self.busy ? "🏗" : self.version!.short)
        self.updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        var string = "We are not sure what version of PHP you are running."
        if (version != nil) {
            string = "You are running PHP \(version!.long)"
        }
        menu.addItem(NSMenuItem(title: string, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        if (self.availablePhpVersions.count > 0 && !busy) {
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
        menu.addItem(NSMenuItem(title: "Quit phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func switchToPhpVersion(sender: AnyObject) {
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

