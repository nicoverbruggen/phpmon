//
//  NSMenuExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenu {
    convenience init(items: [NSMenuItem], target: NSObject? = nil) {
        self.init()
        self.addItems(items, target: target)
    }

    public func addItems(_ items: [NSMenuItem], target: NSObject? = nil) {
        for item in items {
            self.addItem(item)
            if target != nil {
                item.target = target
            }
        }
    }
}
