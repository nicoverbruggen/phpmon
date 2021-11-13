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
    
    // Labels on the left
    @IBOutlet weak var leftLabelDynamicIcon: NSTextField!
    @IBOutlet weak var leftLabelGlobalShortcut: NSTextField!
    
    // Dynamic icon
    @IBOutlet weak var buttonDynamicIcon: NSButton!
    @IBOutlet weak var labelDynamicIcon: NSTextField!
    
    // Full PHP version
    @IBOutlet weak var buttonDisplayFullPhpVersion: NSButton!
    @IBOutlet weak var labelDisplayFullPhpVersion: NSTextField!
    
    // Shortcut
    @IBOutlet weak var buttonSetShortcut: NSButton!
    @IBOutlet weak var buttonClearShortcut: NSButton!
    @IBOutlet weak var labelShortcut: NSTextField!
    
    // Close button (bottom right)
    @IBOutlet weak var buttonClose: NSButton!
    
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
        loadLocalization()
        loadDynamicIconFromPreferences()
        loadFullPhpVersionFromPreferences()
        loadGlobalKeybindFromPreferences()
    }
    
    override func viewWillDisappear() {
        if self.listeningForGlobalHotkey {
            listeningForGlobalHotkey = false
        }
    }
    
    private func loadLocalization() {
        // Dynamic icon
        leftLabelDynamicIcon.stringValue = "prefs.dynamic_icon".localized
        labelDynamicIcon.stringValue = "prefs.dynamic_icon_desc".localized
        buttonDynamicIcon.title = "prefs.dynamic_icon_title".localized
        
        // Full PHP version
        buttonDisplayFullPhpVersion.title = "prefs.display_full_php_version".localized
        labelDisplayFullPhpVersion.stringValue = "prefs.display_full_php_version_desc".localized
        
        // Global Shortcut
        leftLabelGlobalShortcut.stringValue = "prefs.global_shortcut".localized
        labelShortcut.stringValue = "prefs.shortcut_desc".localized
        buttonSetShortcut.title = "prefs.shortcut_set".localized
        buttonClearShortcut.title = "prefs.shortcut_clear".localized
        
        // Close button
        buttonClose.title = "prefs.close".localized
    }
    
    // MARK: - Loading Preferences
    
    func loadDynamicIconFromPreferences() {
        let shouldDisplay = Preferences.preferences[.shouldDisplayDynamicIcon] as! Bool == true
        self.buttonDynamicIcon.state = shouldDisplay ? .on : .off
    }
    
    func loadFullPhpVersionFromPreferences() {
        let shouldDisplay = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool == true
        self.buttonDisplayFullPhpVersion.state = shouldDisplay ? .on : .off
    }
    
    // MARK: - Actions
    
    @IBAction func toggledDynamicIcon(_ sender: Any) {
        Preferences.update(.shouldDisplayDynamicIcon, value: buttonDynamicIcon.state == .on)
        MainMenu.shared.refreshIcon()
    }
    
    @IBAction func toggledFullPhpVersion(_ sender: Any) {
        Preferences.update(.fullPhpVersionDynamicIcon, value: buttonDisplayFullPhpVersion.state == .on)
        MainMenu.shared.refreshIcon()
    }
    
    // MARK: - Shortcut Preference
    // Adapted from: https://dev.to/mitchartemis/creating-a-global-configurable-shortcut-for-macos-apps-in-swift-25e9
    
    var listeningForGlobalHotkey = false {
        didSet {
            if listeningForGlobalHotkey {
                DispatchQueue.main.async { [weak self] in
                    self?.buttonSetShortcut.highlight(true)
                    self?.buttonSetShortcut.title = "prefs.shortcut_listening".localized
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.buttonSetShortcut.highlight(false)
                    self?.loadGlobalKeybindFromPreferences()
                }
            }
        }
    }
    
    func loadGlobalKeybindFromPreferences() {
        let globalKeybind = GlobalKeybindPreference.fromJson(Preferences.preferences[.globalHotkey] as! String?)
        
        if (globalKeybind != nil) {
            updateKeybindButton(globalKeybind!)
        } else {
            buttonSetShortcut.title = "prefs.shortcut_set".localized
        }
        
        buttonClearShortcut.isEnabled = globalKeybind != nil
    }
    
    func updateGlobalShortcut(_ event : NSEvent) {
        self.listeningForGlobalHotkey = false
        
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
        listeningForGlobalHotkey = true
        view.window?.makeFirstResponder(nil)
    }
    
    @IBAction func unregister(_ sender: Any?) {
        listeningForGlobalHotkey = false
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
    
    @IBAction func pressed(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}
