//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum PreferenceName: String {
    case shouldDisplayDynamicIcon = "use_dynamic_icon"
    case fullPhpVersionDynamicIcon = "full_php_in_menu_bar"
    case globalHotkey = "global_hotkey"
}

class Preferences {
    
    static func handleFirstTimeLaunch() {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launched_before")
        
        if launchedBefore {
            return
        }
        
        // Set sensible defaults
        UserDefaults.standard.setValue(true, forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue)
        UserDefaults.standard.setValue(false, forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue)
        UserDefaults.standard.setValue(true, forKey: "launched_before")
        UserDefaults.standard.synchronize()
        
        print("Saving first-time preferences!")
    }
    
    static func handleMissingPreferences() {
        var migrated = false
        
        // Any defaults that need to be adopted in case they are missing?
        // If any new preferences are added in updates, they should get a default value here!
        if UserDefaults.standard.value(forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue) == nil {
            UserDefaults.standard.setValue(false, forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue)
            migrated = true
        }
        
        if migrated {
            UserDefaults.standard.synchronize()
        }
    }
    
    static func retrieve() -> [PreferenceName: Any] {
        Preferences.handleFirstTimeLaunch()
        Preferences.handleMissingPreferences()
        
        return [
            .shouldDisplayDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue) as Any,
            .fullPhpVersionDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue) as Any,
            .globalHotkey: UserDefaults.standard.string(forKey: PreferenceName.globalHotkey.rawValue) as Any,
        ]
    }
    
    static var preferences: [PreferenceName: Any?] {
        return Preferences.retrieve()
    }
    
    static func update(_ preference: PreferenceName, value: Any?) {
        if (value == nil) {
            UserDefaults.standard.removeObject(forKey: preference.rawValue)
        } else {
            UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        }
        UserDefaults.standard.synchronize()
    }
    
}
