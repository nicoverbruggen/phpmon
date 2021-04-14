//
//  NSMenuExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenu {
    
    open func addItem(_ newItem: NSMenuItem, withKeyModifier modifier: NSEvent.ModifierFlags) {
        newItem.keyEquivalentModifierMask = modifier
        self.addItem(newItem)
    }
    
}
