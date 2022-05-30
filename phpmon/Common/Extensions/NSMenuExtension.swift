//
//  NSMenuExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenu {

    open func addItem(_ newItem: NSMenuItem, withKeyModifier modifier: NSEvent.ModifierFlags) {
        newItem.keyEquivalentModifierMask = modifier
        self.addItem(newItem)
    }

}

@IBDesignable class LocalizedMenuItem: NSMenuItem {

    @IBInspectable
    var localizationKey: String? {
        didSet {
            self.title = localizationKey?.localized ?? self.title
        }
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
