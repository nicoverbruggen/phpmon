//
//  HeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class HeaderView: NSView, XibLoadable {

    @IBOutlet weak var textField: NSTextField!

    static func asMenuItem(
        text: String,
        width: Int? = nil
    ) -> NSMenuItem {
        let view = Self.createFromXib()!

        view.autoresizingMask = [.width, .height]

        view.textField.stringValue = text.uppercased()
        view.textField.sizeToFit()

        view.setFrameSize(CGSize(width: view.textField.frame.width + 40, height: view.frame.height))

        let item = NSMenuItem()
        item.view = view
        item.target = self

        return item
    }

}
