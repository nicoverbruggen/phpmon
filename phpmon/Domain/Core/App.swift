//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey

class App {
    
    // MARK: Static Vars
    
    /** The static app instance. Accessible at any time. */
    static let shared = App()
    
    /** Retrieve the version number from the main info dictionary, Info.plist. */
    static var version: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return "\(version) (\(build))"
    }
    
    /** Information about the currently linked PHP installation. */
    static var phpInstall: ActivePhpInstallation? {
        return App.shared.currentInstall
    }
    
    /** Whether the app is busy doing something. Used to determine what UI to display. */
    static var busy: Bool {
        return App.shared.busy
    }
    
    // MARK: - Initializer

    /** When the app boots up, this code will run even before the start-up checks. */
    init() {
        loadGlobalHotkey()
    }
    
    // MARK: Variables
    
    /** The list of preferences that are currently active. */
    var preferences: [PreferenceName: Bool]!
    
    /** The window controller of the currently active preferences window. */
    var preferencesWindowController: PrefsWC? = nil
    
    /** The window controller of the currently active site list window. */
    var siteListWindowController: SiteListWC? = nil
    
    /** Whether the application is busy switching versions. */
    var busy: Bool = false
    
    /** The currently active installation of PHP. */
    var currentInstall: ActivePhpInstallation? = nil
    
    /** All available versions of PHP. */
    var availablePhpVersions: [String] = []
    
    /** Cached information about the PHP installations. */
    var cachedPhpInstallations: [String: PhpInstallation] = [:]
    
    /** List of detected (installed) applications that PHP Monitor can work with. */
    var detectedApplications: [Application] = []
    
    /** Timer that will periodically reload info about the user's PHP installation. */
    var timer: Timer?
    
    /** Information we were able to discern from the Homebrew info command (as JSON). */
    var brewPhpPackage: HomebrewPackage! = nil {
        didSet {
            brewPhpVersion = brewPhpPackage!.version
        }
    }
    
    /**
     The version that the `php` formula via Brew is aliased to on the current system.
     
     If you're up to date, `php` will be aliased to the latest version,
     but that might not be the case.
     
     We'll technically default to the version in Constants.swift, but the information
     should always be loaded from Homebrew itself upon startup.
     */
    var brewPhpVersion: String = Constants.LatestStablePhpVersion
    
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
    
}
