//
//  PreferencesWindowController+Hotkey.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/07/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {

    // MARK: - Key Interaction

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        guard let tabVC = self.contentViewController as? NSTabViewController else {
            return
        }

        guard let vc = tabVC.tabViewItems[tabVC.selectedTabViewItemIndex].viewController as? GenericPreferenceVC else {
            return
        }

        if vc.listeningForHotkeyView == nil {
            return
        }

        if event.keyCode == Keys.Escape || event.keyCode == Keys.Space {
            Log.info("A blacklisted key was pressed, canceling listen!")
            vc.listeningForHotkeyView!.unregister(nil)
        } else {
            vc.listeningForHotkeyView!.updateShortcut(event)
        }
    }

}
