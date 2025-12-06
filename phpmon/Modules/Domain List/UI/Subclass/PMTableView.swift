//
//  PMTableView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

/**
 This subclassed version of NSTableView selects a row upon right-clicking,
 thus making the domain list behave more like you'd expect.
 */
public class PMTableView: NSTableView {

    override open func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: self.convert(event.locationInWindow, from: nil))

        if row >= 0 {
            self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }

        return super.menu(for: event)
    }

}
