//
//  NSMenuExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenu {
    /* TODO: convenience initializer with items, target and parent menu item
    convenience init() {
        super.init()
    }
    */

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
