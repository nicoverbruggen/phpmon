//
//  PrefsVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

class PrefsVC: NSViewController {
    
    @IBOutlet weak var buttonDynamicIcon: NSButton!
    @IBOutlet weak var labelDynamicIcon: NSTextField!
    @IBOutlet weak var buttonClose: NSButton!
    
    @IBOutlet weak var buttonSetShortcut: NSButton!
    @IBOutlet weak var buttonClearShortcut: NSButton!
    @IBOutlet weak var labelShortcut: NSTextField!
    
    // MARK: - Variables
    
    var listening = false {
        didSet {
            if listening {
                DispatchQueue.main.async { [weak self] in
                    self?.buttonSetShortcut.highlight(true)
                    self?.buttonSetShortcut.title = "prefs.shortcut_listening".localized
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.buttonSetShortcut.highlight(false)
                    if (App.shared.shortcutHotkey == nil) {
                        self?.buttonSetShortcut.title = "prefs.shortcut_set".localized
                    }
                }
            }
        }
    }
    
    // MARK: - Display
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.windowController == nil) {
            let vc = NSStoryboard(name: "Main", bundle: nil)
                .instantiateController(withIdentifier: "preferences") as! PrefsVC
            let window = NSWindow(contentViewController: vc)
            
            window.title = "prefs.title".localized
            window.delegate = delegate
            window.styleMask = [.titled, .closable]
            
            App.shared.windowController = PrefsWC(window: window)
        }
        
        App.shared.windowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear() {
        // Load localization
        buttonDynamicIcon.title = "prefs.dynamic_icon_title".localized
        labelDynamicIcon.stringValue = "prefs.dynamic_icon_desc".localized
        buttonClose.title = "prefs.close".localized
        labelShortcut.stringValue = "prefs.shortcut_desc".localized
        buttonSetShortcut.title = "prefs.shortcut_set".localized
        buttonClearShortcut.title = "prefs.shortcut_clear".localized
        
        let prefs = Preferences.preferences
        
        // Load dynamic icon
        self.buttonDynamicIcon.state = (prefs[.shouldDisplayDynamicIcon] as! Bool == true) ? .on : .off
        
        // Load global keybind initial state
        let globalKeybind = GlobalKeybindPreference.fromJson(prefs[.globalHotkey] as! String?)
        if (globalKeybind != nil) {
            updateKeybindButton(globalKeybind!)
        }
        buttonClearShortcut.isEnabled = globalKeybind != nil
    }
    
    // MARK: - Shortcut
    // Adapted from: https://dev.to/mitchartemis/creating-a-global-configurable-shortcut-for-macos-apps-in-swift-25e9
    
    func updateGlobalShortcut(_ event : NSEvent) {
        self.listening = false
        
        if let characters = event.charactersIgnoringModifiers {
            let newGlobalKeybind = GlobalKeybindPreference.init(
                function: event.modifierFlags.contains(.function),
                control: event.modifierFlags.contains(.control),
                command: event.modifierFlags.contains(.command),
                shift: event.modifierFlags.contains(.shift),
                option: event.modifierFlags.contains(.option),
                capsLock: event.modifierFlags.contains(.capsLock),
                carbonFlags: event.modifierFlags.carbonFlags,
                characters: characters,
                keyCode: UInt32(event.keyCode)
            )
            
            Preferences.update(.globalHotkey, value: newGlobalKeybind.toJson())
            
            updateKeybindButton(newGlobalKeybind)
            buttonClearShortcut.isEnabled = true
            
            App.shared.shortcutHotkey = HotKey(
                keyCombo: KeyCombo(
                    carbonKeyCode: UInt32(event.keyCode),
                    carbonModifiers: event.modifierFlags.carbonFlags
                )
            )
        }
    }
    
    @IBAction func register(_ sender: Any) {
        unregister(nil)
        listening = true
        view.window?.makeFirstResponder(nil)
    }
    
    @IBAction func unregister(_ sender: Any?) {
        listening = false
        App.shared.shortcutHotkey = nil
        buttonSetShortcut.title = ""
        
        Preferences.update(.globalHotkey, value: nil)
    }
    
    func updateClearButton(_ globalKeybindPreference: GlobalKeybindPreference?) {
        if globalKeybindPreference != nil {
            buttonClearShortcut.isEnabled = true
        } else {
            buttonClearShortcut.isEnabled = false
        }
    }
    
    func updateKeybindButton(_ globalKeybindPreference: GlobalKeybindPreference) {
        buttonSetShortcut.title = globalKeybindPreference.description
    }
    
    // MARK: - Actions
    
    @IBAction func toggledDynamicIcon(_ sender: Any) {
        Preferences.update(.shouldDisplayDynamicIcon, value: buttonDynamicIcon.state == .on)
        MainMenu.shared.refreshIcon()
    }
    
    @IBAction func pressed(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}

struct GlobalKeybindPreference: Codable, CustomStringConvertible {
    
    // MARK: - Internal variables
    
    let function : Bool
    let control : Bool
    let command : Bool
    let shift : Bool
    let option : Bool
    let capsLock : Bool
    let carbonFlags : UInt32
    let characters : String?
    let keyCode : UInt32
    
    // MARK: - How the keybind is display in Preferences
    
    var description: String {
        var stringBuilder = ""
        if self.function {
            stringBuilder += "Fn"
        }
        if self.control {
            stringBuilder += "⌃"
        }
        if self.option {
            stringBuilder += "⌥"
        }
        if self.command {
            stringBuilder += "⌘"
        }
        if self.shift {
            stringBuilder += "⇧"
        }
        if self.capsLock {
            stringBuilder += "⇪"
        }
        if let characters = self.characters {
            stringBuilder += characters.uppercased()
        }
        return "\(stringBuilder)"
    }
    
    // MARK: - Persisting data to UserDefaults (as JSON)
    
    public func toJson() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    public static func fromJson(_ string: String?) -> GlobalKeybindPreference? {
        if string == nil {
            return nil
        }
        
        if let jsonData = string!.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(GlobalKeybindPreference.self, from: jsonData)
            } catch {
                return nil
            }
        }
        return nil
    }
}
