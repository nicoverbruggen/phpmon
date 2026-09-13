//
//  NSMenuItem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/08/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

// Menu construction is UI work; `NSMenuItem` is already main-actor isolated by
// AppKit, and this extension is annotated explicitly to make that intent clear.
@MainActor
extension NSMenuItem {
    convenience init(
        title: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        keyModifier: NSEvent.ModifierFlags = [],
        systemImage: String? = nil,
        customImage: String? = nil,
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.keyEquivalentModifierMask = keyModifier
        self.setImageVisibility()

        if systemImage != nil {
            self.image = NSImage(systemSymbolName: systemImage!, accessibilityDescription: "")
        }
        if customImage != nil {
            self.image = NSImage(named: customImage!)
        }
    }

    convenience init(
        title: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        keyModifier: NSEvent.ModifierFlags = [],
        toolTip: String? = nil
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.keyEquivalentModifierMask = keyModifier
        self.toolTip = toolTip
    }

    convenience init(
        title: String,
        keyEquivalent: String = "",
        keyModifier: NSEvent.ModifierFlags = [],
        toolTip: String? = nil,
        systemImage: String? = nil,
        customImage: String? = nil,
        submenu: [NSMenuItem],
        target: NSObject? = nil
    ) {
        self.init(title: title, action: nil, keyEquivalent: keyEquivalent)
        self.keyEquivalentModifierMask = keyModifier
        self.toolTip = toolTip
        self.setImageVisibility()

        if systemImage != nil {
            self.image = NSImage(systemSymbolName: systemImage!, accessibilityDescription: "")
        }

        if customImage != nil {
            self.image = NSImage(named: customImage!)
        }

        self.submenu = NSMenu(items: submenu, target: target)
    }

    /**
     TODO: Clean this up once I switch to Xcode 27.
     */
    fileprivate func setImageVisibility() {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            self.preferredImageVisibility = .visible
        }
        #endif
    }
}

// MARK: - NSMenuItem subclasses

// `nonisolated`: `NSMenuItem`'s initializers are nonisolated in the AppKit SDK, so these
// subclasses must be nonisolated too or their (main-actor-by-default) init overrides would
// mismatch the parent. The inherited main-actor `NSMenuItem` API is still only ever touched
// from the main actor (menu building), which is allowed on a nonisolated instance.
nonisolated class PhpMenuItem: NSMenuItem {
    var version: String = ""
}

nonisolated class XdebugMenuItem: NSMenuItem {
    var mode: String = ""
}

nonisolated class ExtensionMenuItem: NSMenuItem {
    var phpExtension: PhpExtension?
}

nonisolated class ApplicationMenuItem: NSMenuItem {
    var app: Application?
}

nonisolated class PresetMenuItem: NSMenuItem {
    var preset: Preset?

    // Kept on the main actor: it sets `attributedTitle` (a main-actor `NSMenuItem` property).
    @MainActor static func getAll() -> [NSMenuItem] {
        return Preferences.custom.presets!.map { preset in
            let presetMenuItem = PresetMenuItem(
                title: preset.getMenuItemText(),
                action: #selector(MainMenu.togglePreset(sender:))
            )

            if let attributedString = try? NSMutableAttributedString(
                data: preset.getMenuItemText().data(using: .utf8)!,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ) {
                presetMenuItem.attributedTitle = attributedString
            }

            presetMenuItem.preset = preset
            return presetMenuItem
        }
    }
}
