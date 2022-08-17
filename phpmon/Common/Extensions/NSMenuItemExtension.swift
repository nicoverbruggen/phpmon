//
//  NSMenuItem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenuItem {
    convenience init(
        title: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        keyModifier: NSEvent.ModifierFlags = [],
        tooltip: String = "",
        submenu: NSMenu? = nil
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.keyEquivalentModifierMask = keyModifier
    }
}

// MARK: - NSMenuItem subclasses

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
}
