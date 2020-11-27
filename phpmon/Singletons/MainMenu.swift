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
    
    /**
     The status bar item with variable length.
     */
    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )
    
    // MARK: - UI related
    
    /**
     Kick off the startup of the rendering of the main menu.
     */
    public func startup() {
        // Start with the icon
        self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        // Perform environment boot checks
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            Startup().checkEnvironment(success: {
                self.onEnvironmentPass()
            }, failure: {
                self.onEnvironmentFail()
            })
        }
    }
    
    /**
     When the environment is all clear and the app can run, let's go.
     */
    private func onEnvironmentPass() {
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
    
    /**
     When the environment is not OK, present an alert to inform the user.
     */
    private func onEnvironmentFail() {
        DispatchQueue.main.async {
            let close = Alert.present(
                messageText: "alert.cannot_start.title".localized,
                informativeText: "alert.cannot_start.info".localized,
                buttonTitle: "alert.cannot_start.close".localized,
                secondButtonTitle: "alert.cannot_start.retry".localized
            )
            if (!close) {
                self.startup()
            } else {
                exit(1)
            }
        }
    }
    
    /**
     Update the menu's contents, based on what's going on.
     */
    public func update() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            // Create a new menu
            let menu = StatusMenu()
            
            // Add the PHP versions (or error messages)
            menu.addPhpVersionMenuItems()
            menu.addItem(NSMenuItem.separator())
            
            // Add the possible actions
            menu.addPhpActionMenuItems()
            menu.addItem(NSMenuItem.separator())
            
            // Add information about services & actions
            menu.addPhpConfigurationMenuItems()
            menu.addItem(NSMenuItem.separator())
            
            // Add about & quit menu items
            menu.addItem(NSMenuItem(title: "mi_about".localized, action: #selector(self.openAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "mi_quit".localized, action: #selector(self.terminateApp), keyEquivalent: "q"))
            
            // Make sure every item can be interacted with
            menu.items.forEach({ (item) in
                item.target = self
            })
            
            // Update the menu item on the main thread
            DispatchQueue.main.async {
                self.statusItem.menu = menu
            }
        }
    }
    
    /**
     Sets the status bar image based on a version string.
     */
    func setStatusBarImage(version: String) {
        self.setStatusBar(
            image: MenuBarImageGenerator.textToImage(text: version)
        )
    }
    
    /**
     Sets the status bar image, based on the provided NSImage.
     The image will be used as a template image.
     */
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }
    
    // MARK: - Nicer callbacks
    
    /**
     Executes a specific callback and fires the completion callback,
     while updating the UI as required. As long as the completion callback
     does not fire, the app is presumed to be busy and the UI reflects this.
     
     - Parameter execute: Escaping callback of the work that needs to happen.
     - Parameter completion: Callback that is fired when the work is done.
     */
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
    
    // MARK: - User Interface
    
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
    
    // MARK: - Actions
    
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
    
    @objc public func openPhpInfo() {
        self.waitAndExecute({
            try! "<?php phpinfo();".write(toFile: "/tmp/phpmon_phpinfo.php", atomically: true, encoding: .utf8)
            Shell.user.run("/usr/local/bin/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html")
            NSWorkspace.shared.open(URL(string: "file:///private/tmp/phpmon_phpinfo.html")!)
        })
    }
    
    @objc public func forceRestartLatestPhp() {
        // Tell the user the switch is about to occur
        _ = Alert.present(
            messageText: "alert.force_reload.title".localized,
            informativeText: "alert.force_reload.info".localized
        )
        // Start switching
        self.waitAndExecute({ Actions.fixMyPhp() }, {
            _ = Alert.present(
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
        // TODO: A wise man once said: using tags is not good. Fix this.
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
                // Send a notification that the switch has been completed
                LocalNotification.send(
                    title: String(format: "notification.version_changed_title".localized, version),
                    subtitle: String(format: "notification.version_changed_desc".localized, version)
                )
            }
        }
    }
    
    @objc public func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    @objc public func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
}
