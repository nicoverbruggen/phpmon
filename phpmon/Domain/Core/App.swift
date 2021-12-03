//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey

class App {
    
    static let shared = App()
    
    init() {
        loadGlobalHotkey()
    }
    
    /** Information about the currently linked PHP installation. */
    static var phpInstall: ActivePhpInstallation? {
        return App.shared.currentInstall
    }
    
    /** Whether the app is busy doing something. Used to determine what UI to display. */
    static var busy: Bool {
        return App.shared.busy
    }
    
    /** The list of preferences that are currently active. */
    var preferences: [PreferenceName: Bool]!
    
    /**
     The window controller of the currently active preferences window.
     */
    var preferencesWindowController: PrefsWC? = nil
    
    /**
     The window controller of the currently active site list window.
     */
    var siteListWindowController: SiteListWC? = nil
    
    /**
     Whether the application is busy switching versions.
     */
    var busy: Bool = false
    
    /**
     The currently active installation of PHP.
     */
    var currentInstall: ActivePhpInstallation? = nil
    
    /**
     All available versions of PHP.
     */
    var availablePhpVersions : [String] = []
    
    /**
     Cached information about the PHP installations; contains only the full version number at this point.
     */
    var cachedPhpInstallations : [String: PhpInstallation] = [:]
    
    /**
     The timer that will periodically fetch the PHP version that is currently active.
     */
    var timer: Timer?
    
    /**
     Information we were able to discern from the Homebrew info command (as JSON).
     */
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
    
    /**
     The shortcut the user has requested.
     */
    var shortcutHotkey: HotKey? = nil {
        didSet {
            self.setupGlobalHotkeyListener()
        }
    }
    
    // MARK: - Methods
    
    /**
     On startup, the preferences should be loaded from the .plist, and we'll enable the shortcut if it is set.
     */
    private func loadGlobalHotkey() {
        // Make sure we can retrieve the hotkey from preferences; if we cannot, no hotkey is set
        guard let hotkey = Preferences.preferences[.globalHotkey] as? String else {
            print("No global hotkey loaded")
            return
        }
        
        // Make sure we can parse the JSON into the desired format; if we cannot, no hotkey is set
        guard let keybindPref = GlobalKeybindPreference.fromJson(hotkey) else {
            print("No global hotkey loaded, could not be parsed!")
            self.shortcutHotkey = nil
            return
        }
        
        self.shortcutHotkey = HotKey(keyCombo: KeyCombo(
            carbonKeyCode: keybindPref.keyCode,
            carbonModifiers: keybindPref.carbonFlags
        ))
    }
    
    /**
     Sets up the action that needs to occur when the shortcut key is pressed (open the menu).
     */
    private func setupGlobalHotkeyListener() {
        guard let hotkey = self.shortcutHotkey else {
            return
        }
        
        hotkey.keyDownHandler = {
            MainMenu.shared.statusItem.button?.performClick(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
}
