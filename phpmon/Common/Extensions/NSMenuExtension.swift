//
//  NSMenuExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenu {
    open func addItem(
        _ newItem: NSMenuItem,
        withKeyModifier modifier: NSEvent.ModifierFlags
    ) {
        newItem.keyEquivalentModifierMask = modifier
        self.addItem(newItem)
    }

    open func addItems(_ items: [NSMenuItem], target: NSObject? = nil) {
        for item in items {
            self.addItem(item)
            if target != nil {
                item.target = target
            }
        }
    }
}

@IBDesignable class LocalizedMenuItem: NSMenuItem {
    @IBInspectable var localizationKey: String? {
        didSet {
            self.title = localizationKey?.localized ?? self.title
        }
    }
}
