//
//  MainMenuTrackingTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

@Suite(.serialized)
struct MainMenuTrackingTest {
    @Test func closing_a_replaced_menu_resumes_the_shortcut() {
        let previousContainer = App.shared.container
        let previousHotkey = App.shared.shortcutHotkey
        App.shared.container = Container.fake()
        let previousValetInstalled = Valet.shared.installed
        let menu = MainMenu()
        menu.statusItem.isVisible = false
        defer {
            NSStatusBar.system.removeStatusItem(menu.statusItem)
            App.shared.shortcutHotkey = previousHotkey
            App.shared.container = previousContainer
            Valet.shared.installed = previousValetInstalled
        }

        Valet.shared.installed = false
        // An invalid key code avoids registering a usable system shortcut.
        let hotkey = HotKey(keyCombo: KeyCombo(carbonKeyCode: UInt32.max))
        App.shared.shortcutHotkey = hotkey
        let openedMenu = NSMenu()
        menu.statusItem.menu = openedMenu

        NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: openedMenu)
        #expect(hotkey.isPaused)

        menu.rebuildImmediately()
        NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: NSMenu())
        #expect(hotkey.isPaused)
        NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: openedMenu)

        #expect(!hotkey.isPaused)
    }
}
