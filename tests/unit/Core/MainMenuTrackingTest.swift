//
//  MainMenuTrackingTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

struct MainMenuTrackingTest {
    @Test func closing_a_replaced_menu_resumes_the_shortcut() {
        let container = Container.fake()
        container.valet.installed = false
        // An invalid key code avoids registering a usable system shortcut.
        let hotkey = HotKey(keyCombo: KeyCombo(carbonKeyCode: UInt32.max))
        let menu = TrackingTestMenu(container: container, shortcutHotkey: { hotkey })
        menu.statusItem.isVisible = false
        defer { NSStatusBar.system.removeStatusItem(menu.statusItem) }
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

private class TrackingTestMenu: MainMenu {
    override func rebuildImmediately() {
        statusItem.menu = NSMenu()
    }
}
