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
            menu.addItem(NSMenuItem(title: "About PHP Monitor", action: #selector(self.openAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit PHP Monitor", action: #selector(self.terminateApp), keyEquivalent: "q"))
            
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
    
    func setStatusBarImage(version: String) {
        self.setStatusBar(image: MenuBarImageGenerator.textToImage(text: version))
    }
    
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }
    
    // MARK: - Nicer callbacks
    
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
    
    // MARK: - Actions
    
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
    
    @objc public func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Cleanup when window closes
    
    func windowWillClose(_ notification: Notification) {
        App.shared.windowController = nil
        Shell.user.delegate = nil
    }
}
