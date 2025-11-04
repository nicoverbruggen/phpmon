//
//  NSImageExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        newImage.isTemplate = self.isTemplate
        return newImage
    }
}
