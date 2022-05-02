//
//  MainMenu.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSWindowDelegate, NSMenuDelegate, PhpSwitcherDelegate {

    static let shared = MainMenu()
    
    weak var menuDelegate: NSMenuDelegate? = nil
    
    /**
     The status bar item with variable length.
     */
    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )
    
    // MARK: - UI related
    
    /**
     Rebuilds the menu (either asynchronously or synchronously).
     Defaults to rebuilding the menu asynchronously.
     */
    func rebuild(async: Bool = true) {
        if !async {
            self.rebuildMenu()
            return
        }
        
        // Update the menu item on the main thread
        DispatchQueue.main.async { [self] in
            self.rebuildMenu()
        }
    }
    
    /**
     Update the menu's contents, based on what's going on.
     This will rebuild the entire menu, so this can take a few moments.
     
     Use `rebuild(async:)` to ensure the rebuilding happens in the background.
     */
    private func rebuildMenu() {
        // Create a new menu
        let menu = StatusMenu()
        
        // Add the PHP versions (or error messages)
        menu.addPhpVersionMenuItems()
        menu.addItem(NSMenuItem.separator())
        
        // Add the possible actions
        menu.addPhpActionMenuItems()
        menu.addItem(NSMenuItem.separator())
        
        // Add Valet interactions
        menu.addValetMenuItems()
        menu.addItem(NSMenuItem.separator())
        
        // Add services
        menu.addRemainingMenuItems()
        menu.addItem(NSMenuItem.separator())
        
        // Add about & quit menu items
        menu.addCoreMenuItems()
        
        // Make sure every item can be interacted with
        menu.items.forEach({ (item) in
            item.target = self
        })
        
        statusItem.menu = menu
        statusItem.menu?.delegate = self
    }
    
    /**
     Sets the status bar image based on a version string.
     */
    func setStatusBarImage(version: String) {
        setStatusBar(
            image: (Preferences.preferences[.iconTypeToDisplay] as! String != MenuBarIcon.noIcon.rawValue)
                ? MenuBarImageGenerator.textToImageWithIcon(text: version)
                : MenuBarImageGenerator.textToImage(text: version)
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
    
    // MARK: - User Interface
    
    /** Reloads which PHP versions is currently active. */
    @objc func refreshActiveInstallation() {
        if !PhpEnv.shared.isBusy {
            PhpEnv.shared.currentInstall = ActivePhpInstallation()
            updatePhpVersionInStatusBar()
        } else {
            Log.perf("Skipping version refresh due to busy status")
        }
    }
    
    /** Updates the icon (refresh icon) and rebuilds the menu. */
    @objc func updatePhpVersionInStatusBar() {
        refreshIcon()
        rebuild()
    }
    
    /**
     Reloads the menu in the foreground.
     This mimics the exact behaviours of `asyncExecution` as set in the method below.
     */
    @objc func reloadPhpMonitorMenuInForeground() {
        refreshActiveInstallation()
        refreshIcon()
        rebuild(async: false)
        NotificationCenter.default.post(name: Events.ServicesUpdated, object: nil)
    }
    
    /** Reloads the menu in the background, using `asyncExecution`. */
    @objc func reloadPhpMonitorMenuInBackground() {
        asyncExecution({
            // This automatically reloads the menu
            Log.info("Reloading information about the PHP installation (in the background)...")
        }, behaviours: [
            .setsBusyUI,
            .reloadsPhpInstallation,
            .broadcastServicesUpdate,
            .updatesMenuBarContents
        ])
    }
    
    /** Refreshes the icon with the PHP version. */
    @objc func refreshIcon() {
        DispatchQueue.main.async { [self] in
            if (PhpEnv.shared.isBusy) {
                setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
            } else {
                if Preferences.preferences[.shouldDisplayDynamicIcon] as! Bool == false {
                    // Static icon has been requested
                    setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIconStatic"))!)
                } else {
                    // The dynamic icon has been requested
                    let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool
                    setStatusBarImage(version: long ? PhpEnv.phpInstall.version.long  : PhpEnv.phpInstall.version.short)
                }
            }
        }
    }
    
    /** Updates the icon to be displayed as busy. */
    @objc func setBusyImage() {
        DispatchQueue.main.async { [self] in
            setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        }
    }
    
    // MARK: - Actions
    
    @objc func fixHomebrewPermissions() {
        if !BetterAlert()
            .withInformation(
                title: "alert.fix_homebrew_permissions.title".localized,
                subtitle: "alert.fix_homebrew_permissions.subtitle".localized,
                description: "alert.fix_homebrew_permissions.desc".localized
            )
            .withPrimary(text: "alert.fix_homebrew_permissions.ok".localized)
            .withSecondary(text: "alert.fix_homebrew_permissions.cancel".localized)
            .didSelectPrimary() {
            return
        }
        
        asyncExecution {
            try Actions.fixHomebrewPermissions()
        } success: {
            BetterAlert()
                .withInformation(
                    title: "alert.fix_homebrew_permissions_done.title".localized,
                    subtitle: "alert.fix_homebrew_permissions_done.subtitle".localized,
                    description: "alert.fix_homebrew_permissions_done.desc".localized
                )
                .withPrimary(text: "OK")
                .show()
        } failure: { error in
            BetterAlert.show(for: error as! HomebrewPermissionError)
        }
    }
    
    @objc func restartPhpFpm() {
        asyncExecution {
            Actions.restartPhpFpm()
        }
    }
    
    @objc func restartAllServices() {
        asyncExecution {
            Actions.restartDnsMasq()
            Actions.restartPhpFpm()
            Actions.restartNginx()
        } success: {
            DispatchQueue.main.async {
                LocalNotification.send(
                    title: "notification.services_restarted".localized,
                    subtitle: "notification.services_restarted_desc".localized
                )
            }
        }
    }
    
    @objc func stopAllServices() {
        asyncExecution {
            Actions.stopAllServices()
        } success: {
            DispatchQueue.main.async {
                LocalNotification.send(
                    title: "notification.services_stopped".localized,
                    subtitle: "notification.services_stopped_desc".localized
                )
            }
        }
    }
    
    @objc func restartNginx() {
        asyncExecution {
            Actions.restartNginx()
        }
    }
    
    @objc func restartDnsMasq() {
        asyncExecution {
            Actions.restartDnsMasq()
        }
    }
    
    @objc func toggleXdebugMode(sender: XdebugMenuItem) {
        Log.info("Switching Xdebug to mode: \(sender.mode)")
    }
    
    @objc func toggleExtension(sender: ExtensionMenuItem) {
        asyncExecution {
            sender.phpExtension?.toggle()
            
            if Preferences.isEnabled(.autoServiceRestartAfterExtensionToggle) {
                Actions.restartPhpFpm()
            }
        }
    }
    
    @objc func openPhpInfo() {
        var url: URL? = nil
        
        asyncWithBusyUI {
            url = Actions.createTempPhpInfoFile()
        } completion: {
            if url != nil { NSWorkspace.shared.open(url!) }
        }
    }
    
    @objc func updateGlobalComposerDependencies() {
        ComposerWindow().updateGlobalDependencies(
            notify: true,
            completion: { _ in }
        )
    }
    
    @objc func openActiveConfigFolder() {
        if (PhpEnv.phpInstall.version.error) {
            // php version was not identified
            Actions.openGenericPhpConfigFolder()
            return
        }
        
        // php version was identified
        Actions.openPhpConfigFolder(version: PhpEnv.phpInstall.version.short)
    }
    
    @objc func openGlobalComposerFolder() {
        Actions.openGlobalComposerFolder()
    }
    
    @objc func openValetConfigFolder() {
        Actions.openValetConfigFolder()
    }
    
    @objc func switchToPhpVersion(sender: PhpMenuItem) {
        self.switchToPhpVersion(sender.version)
    }
    
    @objc func switchToPhpVersion(_ version: String) {
        setBusyImage()
        PhpEnv.shared.isBusy = true
        PhpEnv.shared.delegate = self
        PhpEnv.shared.delegate?.switcherDidStartSwitching(to: version)
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            updatePhpVersionInStatusBar()
            rebuild()
            PhpEnv.switcher.performSwitch(
                to: version,
                completion: {
                    PhpEnv.shared.delegate?.switcherDidCompleteSwitch(to: version)
                }
            )
        }
    }
    
    // MARK: - Menu Item Functionality
    
    @objc func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    @objc func openPrefs() {
        PrefsVC.show()
    }
    
    @objc func openDomainList() {
        DomainListVC.show()
    }
    
    @objc func openDonate() {
        NSWorkspace.shared.open(Constants.Urls.DonationPage)
    }
    
    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Menu Delegate
    
    func menuWillOpen(_ menu: NSMenu) {
        // Make sure the shortcut key does not trigger this when the menu is open
        App.shared.shortcutHotkey?.isPaused = true
        NotificationCenter.default.post(name: Events.ServicesUpdated, object: nil)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // When the menu is closed, allow the shortcut to work again
        App.shared.shortcutHotkey?.isPaused = false
    }
}
