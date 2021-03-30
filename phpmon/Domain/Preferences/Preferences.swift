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
}

class Preferences {
    
    static func handleFirstTimeLaunch() {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launched_before")
        
        if launchedBefore {
            return
        }
        
        UserDefaults.standard.setValue(true, forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue)
        UserDefaults.standard.setValue(true, forKey: "launched_before")
        UserDefaults.standard.synchronize()
        
        print("Saving first-time preferences!")
    }
    
    static func retrieve() -> [PreferenceName: Bool] {
        Preferences.handleFirstTimeLaunch()
        
        return [
            .shouldDisplayDynamicIcon: UserDefaults.standard.bool(
                forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue
            )
        ]
    }
    
    static var preferences: [PreferenceName: Bool] {
        return Preferences.retrieve()
    }
    
    static func update(_ preference: PreferenceName, value: Bool) {
        UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        UserDefaults.standard.synchronize()
    }
    
}
