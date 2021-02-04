//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class StatsView: NSView, XibLoadable {
    static func asMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.view = Self.createFromXib()
        item.target = self
        return item
    }
}
class HeaderView: NSView, XibLoadable {
    @IBOutlet weak var textField: NSTextField!
    
    static func asMenuItem(text: String) -> NSMenuItem {
        let view = Self.createFromXib()
        view?.textField.stringValue = text.uppercased()
        let item = NSMenuItem()
        item.view = view
        item.target = self
        return item
    }
}
