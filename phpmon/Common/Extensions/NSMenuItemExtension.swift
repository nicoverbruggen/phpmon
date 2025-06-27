//
//  NSMenuItem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

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
        if systemImage != nil {
            self.image = NSImage(systemSymbolName: systemImage!, accessibilityDescription: "")
        }
        if customImage != nil {
            self.image = NSImage(named: customImage!)
        }
        self.submenu = NSMenu(items: submenu, target: target)
    }
}

// MARK: - NSMenuItem subclasses

@IBDesignable class LocalizedMenuItem: NSMenuItem {
    @IBInspectable var localizationKey: String? {
        didSet {
            self.title = localizationKey?.localized ?? self.title
        }
    }
}

class PhpMenuItem: NSMenuItem {
    var version: String = ""
}

class XdebugMenuItem: NSMenuItem {
    var mode: String = ""
}

class ExtensionMenuItem: NSMenuItem {
    var phpExtension: PhpExtension?
}

class EditorMenuItem: NSMenuItem {
    var editor: Application?
}

class PresetMenuItem: NSMenuItem {
    var preset: Preset?

    static func getAll() -> [NSMenuItem] {
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
