//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum PreferenceName: String {
    case wasLaunchedBefore = "launched_before"
    case shouldDisplayDynamicIcon = "use_dynamic_icon"
    case shouldDisplayPhpHintInIcon = "add_php_to_icon"
    case fullPhpVersionDynamicIcon = "full_php_in_menu_bar"
    case autoServiceRestartAfterExtensionToggle = "auto_restart_after_extension_toggle"
    case autoComposerGlobalUpdateAfterSwitch = "auto_composer_global_update_after_switch"
    case allowProtocolForIntegrations = "allow_protocol_for_integrations"
    case globalHotkey = "global_hotkey"
}

class Preferences {
    
    // MARK: - Singleton
    
    static var shared = Preferences()
    
    var customPreferences: CustomPrefs
    
    var cachedPreferences: [PreferenceName: Any?]
    
    public init() {
        Preferences.handleFirstTimeLaunch()
        cachedPreferences = Self.cache()
        customPreferences = CustomPrefs(scanApps: [])
        loadCustomPreferences()
    }
    
    // MARK: - First Time Run
    
    /**
     Note: macOS seems to cache plist values in memory as well as in files.
     You can find the persisted configuration file in: ~/Library/Preferences/com.nicoverbruggen.phpmon.plist
     
     To clear the cache, and get a first-run experience you may need to run:
     ```
     defaults delete com.nicoverbruggen.phpmon
     killall cfprefsd
     ```
     */
    static func handleFirstTimeLaunch() {
        UserDefaults.standard.register(defaults: [
            PreferenceName.shouldDisplayDynamicIcon.rawValue: true,
            PreferenceName.shouldDisplayPhpHintInIcon.rawValue: true,
            PreferenceName.fullPhpVersionDynamicIcon.rawValue: false,
            PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue: true,
            PreferenceName.autoComposerGlobalUpdateAfterSwitch.rawValue: false,
            PreferenceName.allowProtocolForIntegrations.rawValue: true,
        ])
        
        if UserDefaults.standard.bool(forKey: PreferenceName.wasLaunchedBefore.rawValue) {
            return
        }
        
        Log.info("Saving first-time preferences!")
        UserDefaults.standard.setValue(true, forKey: PreferenceName.wasLaunchedBefore.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - API
    
    static var preferences: [PreferenceName: Any?] {
        return Self.shared.cachedPreferences
    }
    
    static var custom: CustomPrefs {
        return Self.shared.customPreferences
    }
    
    /**
     Determine whether a particular preference is enabled.
     - Important: Requires the preference to have a corresponding boolean value, or a fatal error will be thrown.
     */
    static func isEnabled(_ preference: PreferenceName) -> Bool {
        if let bool = Preferences.preferences[preference] as? Bool {
            return bool == true
        } else {
            fatalError("\(preference) is not a valid boolean preference!")
        }
    }
    
    // MARK: - Internal Functionality
    
    private static func cache() -> [PreferenceName: Any] {
        return [
            // Part 1: Always Booleans
            .shouldDisplayDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue) as Any,
            .shouldDisplayPhpHintInIcon: UserDefaults.standard.bool(forKey: PreferenceName.shouldDisplayPhpHintInIcon.rawValue) as Any,
            .fullPhpVersionDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue) as Any,
            .autoServiceRestartAfterExtensionToggle: UserDefaults.standard.bool(forKey: PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue) as Any,
            .autoComposerGlobalUpdateAfterSwitch: UserDefaults.standard.bool(forKey: PreferenceName.autoComposerGlobalUpdateAfterSwitch.rawValue) as Any,
            .allowProtocolForIntegrations: UserDefaults.standard.bool(forKey: PreferenceName.allowProtocolForIntegrations.rawValue) as Any,
            
            // Part 2: Always Strings
            .globalHotkey: UserDefaults.standard.string(forKey: PreferenceName.globalHotkey.rawValue) as Any,
        ]
    }
    
    static func update(_ preference: PreferenceName, value: Any?) {
        if (value == nil) {
            UserDefaults.standard.removeObject(forKey: preference.rawValue)
        } else {
            UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        }
        UserDefaults.standard.synchronize()
        
        // Update the preferences cache in memory!
        Preferences.shared.cachedPreferences = Preferences.cache()
    }
    
    // MARK: - Custom Preferences
    
    private func loadCustomPreferences() {
        let url = URL(fileURLWithPath: "/Users/\(Paths.whoami)/.phpmon.conf.json")
        if Filesystem.fileExists(url.path) {
            Log.info("A custom .phpmon.conf.json file was found. Attempting to parse...")
            loadCustomPreferencesFile(url)
        } else {
            Log.info("There was no .phpmon.conf.json file to be loaded.")
        }
    }
    
    private func loadCustomPreferencesFile(_ url: URL) {
        do {
            customPreferences = try JSONDecoder().decode(
                CustomPrefs.self,
                from: try! String(contentsOf: url, encoding: .utf8).data(using: .utf8)!
            )
            Log.info("The .phpmon.conf.json file was successfully parsed.")
        } catch {
            Log.warn("The .phpmon.conf.json file seems to be missing or malformed.")
        }
    }
    
}
