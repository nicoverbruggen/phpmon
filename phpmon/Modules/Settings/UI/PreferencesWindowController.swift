//
//  PreferencesWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class PreferencesWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Preferences"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()

        guard let window = windowController.window else { return }

        window.title = "prefs.title".localized
        window.subtitle = "prefs.subtitle".localized
        window.delegate = delegate ?? windowController
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.toolbarStyle = .preference

        // A toolbar-style tab view controller hosts the SwiftUI content: this keeps
        // the toolbar tabs (icon above label) that the old storyboard provided,
        // while the tab *content* is fully SwiftUI.
        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar

        for tab in tabs {
            let hostingController = NSHostingController(rootView: tab.content)
            // Track the SwiftUI content's ideal size, so the window resizes to
            // fit each tab's rows — the behavior of the old stack-view-based tabs.
            hostingController.sizingOptions = .preferredContentSize

            let item = NSTabViewItem(viewController: hostingController)
            item.label = tab.label
            item.image = NSImage(systemSymbolName: tab.icon, accessibilityDescription: "\(tab.label) Icon")
            tabViewController.addTabViewItem(item)
        }

        window.contentViewController = tabViewController

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        var justCreated = false

        if !WindowManager.hasController(for: PreferencesWC.self) {
            Self.create(delegate: delegate)
            justCreated = true
        }

        WindowManager.show(PreferencesWC.self)

        if justCreated {
            WindowManager.controller(of: PreferencesWC.self)?
                .positionWindowInTopRightCorner()
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Tabs

    private struct SettingsTab {
        let content: AnyView
        let label: String
        let icon: String
    }

    private static var tabs: [SettingsTab] {
        return [
            SettingsTab(
                content: AnyView(GeneralSettingsView()),
                label: "prefs.tabs.general".localized,
                icon: "gearshape"
            ),
            SettingsTab(
                content: AnyView(AppearanceSettingsView()),
                label: "prefs.tabs.appearance".localized,
                icon: "paintbrush"
            ),
            SettingsTab(
                content: AnyView(MenuStructureSettingsView()),
                label: "prefs.tabs.visibility".localized,
                icon: "eye"
            ),
            SettingsTab(
                content: AnyView(NotificationsSettingsView()),
                label: "prefs.tabs.notifications".localized,
                icon: "bell.badge"
            )
        ]
    }

    // MARK: - Language Switching

    /**
     Invoked when the language override changes: rebuilds the menu and closes
     and reopens every open window (including this one), so all UI picks up
     the newly selected language. Window positions are restored.
     */
    static func handleLanguageChange() {
        // Track which windows we will need to reopen
        let windowsToReopen = captureOpenWindowsForLanguageSwitch()

        // Rebuild the menu
        MainMenu.shared.refreshIcon()
        MainMenu.shared.rebuild()

        // Close all windows
        App.shared.invalidateCachedWindows()

        // Re-open the preferences window controller
        WindowManager.close(PreferencesWC.self)
        PreferencesWindowController.show()

        // Finally, open all other windows again
        reopenWindows(afterLanguageChange: windowsToReopen)
    }
}
