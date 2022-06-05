//
//  HotkeyPreferenceView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class HotkeyPreferenceView: NSView, XibLoadable {

    #warning("Refactor so this applies to any given preferences VC")
    weak var delegate: GeneralPreferencesVC?

    @IBOutlet weak var labelSection: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!

    @IBOutlet weak var buttonSetShortcut: NSButton!
    @IBOutlet weak var buttonClearShortcut: NSButton!

    static func make(sectionText: String, descriptionText: String, _ prefsVC: GeneralPreferencesVC) -> NSView {
        let view = Self.createFromXib()!
        view.labelSection.stringValue = sectionText
        view.labelDescription.stringValue = descriptionText
        view.buttonClearShortcut.title = "prefs.shortcut_clear".localized
        view.delegate = prefsVC
        view.loadGlobalKeybindFromPreferences()
        return view
    }

    // MARK: - Shortcut Functionality

    // Adapted from: https://dev.to/mitchartemis/creating-a-global-configurable-shortcut-for-macos-apps-in-swift-25e9

    func updateShortcut(_ event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers else { return }

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

    func loadGlobalKeybindFromPreferences() {
        let globalKeybind = GlobalKeybindPreference.fromJson(Preferences.preferences[.globalHotkey] as! String?)

        if globalKeybind != nil {
            updateKeybindButton(globalKeybind!)
        } else {
            buttonSetShortcut.title = "prefs.shortcut_set".localized
        }

        buttonClearShortcut.isEnabled = globalKeybind != nil
    }

    func updateKeybindButton(_ globalKeybindPreference: GlobalKeybindPreference) {
        buttonSetShortcut.title = globalKeybindPreference.description
    }

    @IBAction func register(_ sender: Any) {
        unregister(nil)
        delegate?.listeningForHotkeyView = self
        delegate?.view.window?.makeFirstResponder(nil)
        buttonSetShortcut.title = "prefs.shortcut_listening".localized
    }

    @IBAction func unregister(_ sender: Any?) {
        delegate?.listeningForHotkeyView = nil
        App.shared.shortcutHotkey = nil
        buttonSetShortcut.title = "prefs.shortcut_set".localized
        Preferences.update(.globalHotkey, value: nil)
    }

}
