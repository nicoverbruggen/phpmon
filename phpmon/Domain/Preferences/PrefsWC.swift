//
//  PrefsWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

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

        guard let window = windowController.window else { return }

        window.title = "prefs.title".localized
        window.subtitle = "prefs.subtitle".localized
        window.delegate = delegate ?? windowController
        window.styleMask = [.titled, .closable, .miniaturizable]

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
                item?.image = NSImage(systemSymbolName: vc.icon, accessibilityDescription: "\(vc.label) Icon")
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

    // MARK: - Tabs

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

}
