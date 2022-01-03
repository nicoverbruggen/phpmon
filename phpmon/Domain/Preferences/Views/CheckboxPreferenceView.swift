//
//  CheckboxPreferenceView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

import Foundation
import Cocoa

class CheckboxPreferenceView: NSView, XibLoadable {
    
    @IBOutlet weak var labelSection: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var buttonCheckbox: NSButton!
    
    var action: (() -> Void)!
    
    var preference: PreferenceName! {
        didSet {
            self.buttonCheckbox.state = Preferences.isTrue(self.preference) ? .on : .off
        }
    }
    
    static func make(sectionText: String, descriptionText: String, checkboxText: String, preference: PreferenceName, action: @escaping () -> Void) -> NSView {
        let view = Self.createFromXib()!
        view.labelSection.stringValue = sectionText
        view.labelDescription.stringValue = descriptionText
        view.buttonCheckbox.title = checkboxText
        view.preference = preference
        view.action = action
        return view
    }
    
    @IBAction func toggled(_ sender: Any) {
        Preferences.update(self.preference, value: buttonCheckbox.state == .on)
        self.action()
    }
    
}
