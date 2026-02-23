//
//  PreferencesWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

class PreferencesWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Preferences"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        let windowController = storyboard.instantiateController(
            withIdentifier: "preferencesWindow"
        ) as! PreferencesWindowController

        guard let window = windowController.window else { return }

        window.title = "prefs.title".localized
        window.subtitle = "prefs.subtitle".localized
        window.delegate = delegate ?? windowController
        window.styleMask = [.titled, .closable, .miniaturizable]

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        var justCreated = false

        if !WindowManager.hasController(for: PreferencesWC.self) {
            Self.create(delegate: delegate)
            justCreated = true
        }

        guard let preferencesWC = WindowManager.controller(of: PreferencesWC.self) else {
            return
        }

        if justCreated {
            addContentTabs(to: preferencesWC)
        }

        WindowManager.show(PreferencesWC.self)

        if justCreated {
            preferencesWC.positionWindowInTopRightCorner()
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private static func addContentTabs(to preferencesWC: PreferencesWC) {
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
                label: "prefs.tabs.general".localized,
                icon: "gearshape"
            ),
            PrefTabView(
                viewController: AppearancePreferencesVC.fromStoryboard(),
                label: "prefs.tabs.appearance".localized,
                icon: "paintbrush"
            ),
            PrefTabView(
                viewController: MenuStructurePreferencesVC.fromStoryboard(),
                label: "prefs.tabs.visibility".localized,
                icon: "eye"
            ),
            PrefTabView(
                viewController: NotificationPreferencesVC.fromStoryboard(),
                label: "prefs.tabs.notifications".localized,
                icon: "bell.badge"
            )
        ]
    }()

}
