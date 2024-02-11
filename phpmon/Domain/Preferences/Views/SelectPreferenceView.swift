//
//  SelectPreferenceView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

struct PreferenceDropdownOption {
    let label: String
    let value: String
}

class SelectPreferenceView: NSView, XibLoadable {
    @IBOutlet weak var labelSection: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var popupButton: NSPopUpButton!

    var localizationPrefix: String?
    var imagePrefix: String?

    var options: [PreferenceDropdownOption] = [] {
        didSet {
            self.popupButton.removeAllItems()
            self.options.forEach { option in
                if let prefix = localizationPrefix {
                    self.popupButton.addItem(withTitle: "\(prefix).\(option.label)".localized)
                } else {
                    self.popupButton.addItem(withTitle: option.label)
                }
            }

            if let prefix = imagePrefix {
                self.popupButton.itemArray.enumerated().forEach { item in
                    item.element.image = NSImage(named: "\(prefix)_\(self.options[item.offset].value)")
                }
            }
        }
    }

    var action: (() -> Void)!

    var preference: PreferenceName! {
        didSet {
            let value = Preferences.preferences[preference] as! String
            self.options.enumerated().forEach { option in
                if option.element.value == value {
                    self.popupButton.selectItem(at: option.offset)
                }
            }
        }
    }

    static func make(
        sectionText: String,
        descriptionText: String,
        options: [PreferenceDropdownOption],
        localizationPrefix: String? = nil,
        imagePrefix: String? = nil,
        preference: PreferenceName,
        action: @escaping () -> Void) -> NSView {
        let view = Self.createFromXib()!

        view.labelSection.stringValue = sectionText
        view.labelDescription.stringValue = descriptionText

        view.localizationPrefix = localizationPrefix
        view.imagePrefix = imagePrefix
        view.options = options
        view.preference = preference
        view.action = action

        return view
    }

    @IBAction func valueChanged(_ sender: Any) {
        let index = self.popupButton.indexOfSelectedItem
        Preferences.update(self.preference, value: self.options[index].value)
        self.action()
    }

}
