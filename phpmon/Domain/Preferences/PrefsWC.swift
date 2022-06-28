//
//  PrefsWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

struct Keys {
    static let Escape = 53
    static let Space = 49
}

class PrefsWC: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Preferences"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        let windowController = storyboard.instantiateController(
            withIdentifier: "preferencesWindow"
        ) as! PrefsWC

        windowController.window!.title = "prefs.title".localized
        windowController.window!.subtitle = "prefs.subtitle".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [.titled, .closable, .miniaturizable]
        windowController.window!.delegate = windowController

        App.shared.preferencesWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        var justCreated = false

        if App.shared.preferencesWindowController == nil {
            Self.create(delegate: delegate)

            guard let preferencesWC = App.shared.preferencesWindowController else {
                return
            }

            guard let tabVC = preferencesWC.contentViewController as? NSTabViewController else {
                return
            }

            for vc in preferencesWC.tabVCs {
                tabVC.addChild(vc.viewController)
                let item = tabVC.tabViewItem(for: vc.viewController)
                item?.image = NSImage(systemSymbolName: vc.icon, accessibilityDescription: "")
                item?.label = vc.label
            }

            tabVC.preferredContentSize = NSSize(
                width: tabVC.view.frame.size.width,
                height: tabVC.view.frame.size.height
            )

            justCreated = true
        }

        App.shared.preferencesWindowController?.showWindow(self)

        if justCreated {
            App.shared.preferencesWindowController?.positionWindowInTopLeftCorner()
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    struct PrefTabView {
        let viewController: GenericPreferenceVC
        let label: String
        let icon: String
    }

    public lazy var tabVCs: [PrefTabView] = {
        return [
            PrefTabView(
                viewController: GeneralPreferencesVC.fromStoryboard(),
                label: "General",
                icon: "gearshape"
            ),
            PrefTabView(
                viewController: AppearancePreferencesVC.fromStoryboard(),
                label: "Appearance",
                icon: "paintbrush"
            ),
            PrefTabView(
                viewController: NotificationPreferencesVC.fromStoryboard(),
                label: "Notifications",
                icon: "bell.badge"
            )
        ]
    }()

    // MARK: - Key Interaction

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        guard let tabVC = self.contentViewController as? NSTabViewController else {
            return
        }

        guard let selected = tabVC.tabViewItems[tabVC.selectedTabViewItemIndex].viewController else {
            return
        }

        if let vc = selected as? GenericPreferenceVC {
            if vc.listeningForHotkeyView != nil {
                if event.keyCode == Keys.Escape || event.keyCode == Keys.Space {
                    Log.info("A blacklisted key was pressed, canceling listen!")
                    vc.listeningForHotkeyView!.unregister(nil)
                } else {
                    vc.listeningForHotkeyView!.updateShortcut(event)
                }
            }
        }
    }

}
