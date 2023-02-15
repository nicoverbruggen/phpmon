//
//  CheckboxPreferenceView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class CheckboxPreferenceView: NSView, XibLoadable {
    @IBOutlet weak var labelSection: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var buttonCheckbox: NSButton!

    var action: (() -> Void)!
    var behavior: CheckboxPreferenceViewBehavior!

    static func make(
        sectionText: String,
        descriptionText: String,
        checkboxText: String,
        preference: PreferenceName,
        action: @escaping () -> Void
    ) -> NSView {
        let view = Self.createFromXib()!
        view.behavior = CheckboxPreferenceBehavior(
            button: view.buttonCheckbox,
            preference: preference
        )
        view.labelSection.stringValue = sectionText
        view.labelDescription.stringValue = descriptionText
        view.buttonCheckbox.title = checkboxText
        view.action = action
        return view
    }

    @available(macOS 13.0, *)
    static func makeLoginItemView() -> NSView {
        let view = Self.createFromXib()!
        view.behavior = CheckboxLaunchItemBehavior(button: view.buttonCheckbox)
        view.labelSection.stringValue = "prefs.startup".localized
        view.labelDescription.stringValue = "prefs.auto_start_desc".localized
        view.buttonCheckbox.title = "prefs.auto_start_title".localized
        view.action = {}
        return view
    }

    @IBAction func toggled(_ sender: Any) {
        self.behavior.toggled(checked: buttonCheckbox.state == .on)
        self.action()
    }
}

protocol CheckboxPreferenceViewBehavior {
    func toggled(checked: Bool)
}

class CheckboxPreferenceBehavior: CheckboxPreferenceViewBehavior {
    var button: NSButton
    var preference: PreferenceName {
        didSet {
            button.state = Preferences.isEnabled(self.preference) ? .on : .off
        }
    }

    init(button: NSButton, preference: PreferenceName) {
        self.button = button
        self.preference = preference
    }

    public func toggled(checked: Bool) {
        Preferences.update(self.preference, value: checked)
    }
}

@available(macOS 13.0, *)
class CheckboxLaunchItemBehavior: CheckboxPreferenceViewBehavior {
    var manager = LoginItemManager()
    var button: NSButton

    init(button: NSButton) {
        self.button = button

        if manager.loginItemIsEnabled() {
            self.button.state = .on
        } else {
            self.button.state = .off
        }
    }

    public func toggled(checked: Bool) {
        if checked {
            self.manager.enableLoginItem()
        } else {
            self.manager.disableLoginItem()
        }

        self.button.state = self.manager.loginItemIsEnabled() ? .on : .off
    }
}
