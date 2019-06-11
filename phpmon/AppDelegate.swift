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

    let statusItem = NSStatusBar.system.statusItem(
        withLength: 32
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
            button.action = #selector(updatePhpVersionInStatusBar)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func updatePhpVersionInStatusBar() {
        self.version = PhpVersionExtractor()
        self.setStatusBarImage(version: self.version!.short)
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
        /*
        // TODO: Add menu items based on available PHP versions
        menu.addItem(NSMenuItem(title: "Switch to PHP 5.6", action: #selector(switchPhpVersion(version:)), keyEquivalent: "1"))
        menu.addItem(NSMenuItem.separator())
        */
        menu.addItem(NSMenuItem(title: Services.mysqlIsRunning() ? "You are running MySQL" : "MySQL is not active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: Services.nginxIsRunning() ? "You are running nginx" : "nginx is not active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit phpmon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

