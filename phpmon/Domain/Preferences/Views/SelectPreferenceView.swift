//
//  SelectPreferenceView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class SelectPreferenceView: NSView, XibLoadable {

    @IBOutlet weak var labelSection: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var popupButton: NSPopUpButton!

    var localizationPrefix: String = ""
    var imagePrefix: String?

    var options: [String] = [] {
        didSet {
            self.popupButton.removeAllItems()
            self.options.forEach { value in
                self.popupButton.addItem(
                    withTitle: "\(localizationPrefix).\(value)".localized
                )
            }

            if imagePrefix == nil {
                return
            }

            self.popupButton.itemArray.enumerated().forEach { item in
                item.element.image = NSImage(named: "\(imagePrefix!)_\(self.options[item.offset])")
            }
        }
    }

    var action: (() -> Void)!

    var preference: PreferenceName! {
        didSet {
            let value = Preferences.preferences[preference] as! String
            self.options.enumerated().forEach { option in
                if option.element == value {
                    self.popupButton.selectItem(at: option.offset)
                }
            }
        }
    }

    // swiftlint:disable function_parameter_count
    static func make(
        sectionText: String,
        descriptionText: String,
        options: [String],
        localizationPrefix: String,
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
    // swiftlint:enable function_parameter_count

    @IBAction func valueChanged(_ sender: Any) {
        let index = self.popupButton.indexOfSelectedItem
        Preferences.update(.iconTypeToDisplay, value: self.options[index])
        self.action()
    }

}
