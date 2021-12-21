//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey

class App: PhpSwitcherDelegate {
    
    // MARK: Static Vars
    
    /** The static app instance. Accessible at any time. */
    static let shared = App()
    
    init() {
        PhpSwitcher.shared.delegate = self
    }
    
    /** Retrieve the version number from the main info dictionary, Info.plist. */
    static var version: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return "\(version) (\(build))"
    }
    
    /** Whether the app is busy doing something. Used to determine what UI to display. */
    static var busy: Bool {
        return PhpSwitcher.shared.isBusy
    }
    
    // MARK: Variables
    
    /** The list of preferences that are currently active. */
    var preferences: [PreferenceName: Bool]!
    
    /** The window controller of the currently active preferences window. */
    var preferencesWindowController: PrefsWC? = nil
    
    /** The window controller of the currently active site list window. */
    var siteListWindowController: SiteListWC? = nil
    
    /** List of detected (installed) applications that PHP Monitor can work with. */
    var detectedApplications: [Application] = []
    
    /** Timer that will periodically reload info about the user's PHP installation. */
    var timer: Timer?
    

    // MARK: - Global Hotkey
    
    /**
     The shortcut the user has requested.
     */
    var shortcutHotkey: HotKey? = nil {
        didSet {
            setupGlobalHotkeyListener()
        }
    }
    
    // MARK: - Activation Policy
    
    /**
     Variable that keeps track of which windows are currently open.
     (Please note that window controllers remain open in memory once opened.)
     
     When this list is updated, the app activation policy is re-evaluated.
     The app activation policy dictates how the app runs
     (as a normal app or as a toolbar app).
     */
    var openWindows: [String] = []
    
    // MARK: - App Watchers
    
    /**
     The `PhpConfigWatcher` is responsible for watching the `.ini` files and the `.conf.d` folder.
     */
    var watcher: PhpConfigWatcher!
    
    // MARK: - PhpSwitcherDelegate
    
    func switcherDidStartSwitching() {
    }
    
    func switcherDidCompleteSwitch() {
        PhpSwitcher.shared.currentInstall = ActivePhpInstallation()
        handlePhpConfigWatcher()
    }
}
