//
//  SettingsHotkeyRow.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

/**
 The global shortcut recorder: a button that shows the current key combination
 (or "listening" while recording) plus a clear button.

 While listening, a local `NSEvent` monitor captures the next key press.
 Escape and Space cancel the recording, matching the old XIB-based behavior
 (which also documents the spacebar cancel in the description text).
 */
struct SettingsHotkeyRow: View {
    @State private var keybind: GlobalKeybindPreference?
    @State private var listening: Bool = false
    @State private var monitor: Any?

    var body: some View {
        SettingsRow(sectionKey: "prefs.global_shortcut", descriptionKey: "prefs.shortcut_desc") {
            HStack(spacing: 12) {
                // The fixed widths (170/124 outer) match the old XIB buttons;
                // the frame is applied to the label so the bezel stretches.
                Button(action: startListening) {
                    Text(setButtonTitle).frame(width: 146)
                }

                Button(action: clearShortcut) {
                    Text("prefs.shortcut_clear".localized).frame(width: 100)
                }
                .disabled(keybind == nil && !listening)
            }
        }
        .onAppear {
            keybind = GlobalKeybindPreference.fromJson(
                Preferences.preferences[.globalHotkey] as? String
            )
        }
        .onDisappear {
            stopListening()
        }
    }

    private var setButtonTitle: String {
        if listening {
            return "prefs.shortcut_listening".localized
        }

        return keybind?.description ?? "prefs.shortcut_set".localized
    }

    private func startListening() {
        guard let window = WindowManager.window(for: PreferencesWC.self) else { return }

        // Match the old behavior: starting a new recording clears the
        // existing shortcut first.
        clearShortcut()

        listening = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak window] event in
            // Local monitors receive events for every window in the app.
            guard let window, event.window === window else { return event }
            handle(event)
            // Swallow the event: it is being recorded, not typed.
            return nil
        }
    }

    private func stopListening() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = nil
        listening = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == Keys.Escape || event.keyCode == Keys.Space {
            Log.info("A blacklisted key was pressed, canceling listen!")
            stopListening()
            return
        }

        guard let characters = event.charactersIgnoringModifiers else { return }

        let newKeybind = GlobalKeybindPreference(
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

        Preferences.update(.globalHotkey, value: newKeybind.toJson())

        App.shared.shortcutHotkey = HotKey(
            keyCombo: KeyCombo(
                carbonKeyCode: UInt32(event.keyCode),
                carbonModifiers: event.modifierFlags.carbonFlags
            )
        )

        keybind = newKeybind
        stopListening()
    }

    private func clearShortcut() {
        stopListening()
        App.shared.shortcutHotkey = nil
        Preferences.update(.globalHotkey, value: nil)
        keybind = nil
    }
}
