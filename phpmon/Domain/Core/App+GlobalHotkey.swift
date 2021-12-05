//
//  App+GlobalHotkey.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import HotKey
import Cocoa

extension App {
    
    // MARK: - Methods
    
    /**
     On startup, the preferences should be loaded from the .plist,
     and we'll enable the shortcut if it is set.
     */
    func loadGlobalHotkey() {
        // Make sure we can retrieve the hotkey from preferences
        guard let hotkey = Preferences.preferences[.globalHotkey] as? String else {
            print("No global hotkey loaded")
            return
        }
        
        // Make sure we can parse the JSON into the desired format
        guard let keybindPref = GlobalKeybindPreference.fromJson(hotkey) else {
            print("No global hotkey loaded, could not be parsed!")
            shortcutHotkey = nil
            return
        }
        
        shortcutHotkey = HotKey(keyCombo: KeyCombo(
            carbonKeyCode: keybindPref.keyCode,
            carbonModifiers: keybindPref.carbonFlags
        ))
    }
    
    /**
     Sets up the action that needs to occur when the shortcut key is pressed
     (opens the menu).
     */
    func setupGlobalHotkeyListener() {
        guard let hotkey = shortcutHotkey else {
            return
        }
        
        hotkey.keyDownHandler = {
            MainMenu.shared.statusItem.button?.performClick(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
}
