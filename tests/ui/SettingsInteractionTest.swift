//
//  SettingsInteractionTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

/**
 Tests interactions inside the Settings window (the SwiftUI implementation):
 checkbox state surviving tab switches, and the global shortcut recorder.
 `SettingsTest` covers the language switch separately.

 With a testable configuration active, preference changes stay in-memory, so
 nothing in here pollutes the persisted defaults on the machine.
 */
final class SettingsInteractionTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openSettings(_ app: XCPMApplication) -> XCUIElement {
        app.menuItems["mi_preferences".localized(for: "en")].click()

        let window = app.windows
            .containing(.button, identifier: "prefs.tabs.general".localized(for: "en"))
            .firstMatch
        assertExists(window, 2.0)
        return window
    }

    final func test_checkbox_toggles_persist_across_tab_switches() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)
        let window = openSettings(app)

        let checkbox = window.checkBoxes["prefs.auto_restart_services_title".localized(for: "en")]
        assertExists(checkbox, 2.0)

        let initialValue = checkbox.value as? Int
        checkbox.click()
        XCTAssertNotEqual(checkbox.value as? Int, initialValue)

        // Switch to another tab and back: the flipped state must survive
        app.buttons["prefs.tabs.notifications".localized(for: "en")].click()
        assertExists(window.checkBoxes["prefs.notify_about_version_change".localized(for: "en")], 2.0)

        app.buttons["prefs.tabs.general".localized(for: "en")].click()
        assertExists(checkbox, 2.0)
        XCTAssertNotEqual(checkbox.value as? Int, initialValue)
    }

    final func test_hotkey_recorder_captures_and_clears_shortcut() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)
        app.mainMenuItem(withText: "mi_domain_list".localized(for: "en")).click()
        let domainsWindow = app.windows["domain_list.title".localized(for: "en")]
        assertExists(domainsWindow, 2.0)
        app.statusItems.firstMatch.click()
        let window = openSettings(app)

        let setButton = window.buttons["prefs.shortcut_set".localized(for: "en")]
        let clearButton = window.buttons["prefs.shortcut_clear".localized(for: "en")]
        assertExists(setButton, 2.0)
        assertExists(clearButton, 2.0)
        XCTAssertFalse(clearButton.isEnabled)

        // Start recording: the button switches to its listening state
        setButton.click()
        assertExists(window.buttons["prefs.shortcut_listening".localized(for: "en")], 2.0)

        // Recording in Settings must not consume typing in another window.
        app.statusItems.firstMatch.click()
        app.mainMenuItem(withText: "mi_domain_list".localized(for: "en")).click()
        let searchField = domainsWindow.searchFields.firstMatch
        searchField.click()
        searchField.typeText("concord")
        XCTAssertEqual(searchField.value as? String, "concord")

        app.statusItems.firstMatch.click()
        _ = openSettings(app)
        window.buttons["prefs.shortcut_listening".localized(for: "en")].click()

        // Press a (deliberately obscure) combination; the recorder captures it
        app.typeKey("u", modifierFlags: [.control, .option, .command])
        assertExists(window.buttons["⌃⌥⌘U"], 2.0)
        XCTAssertTrue(clearButton.isEnabled)

        // Clearing restores the initial state (and unregisters the hotkey)
        clearButton.click()
        assertExists(setButton, 2.0)
        XCTAssertFalse(clearButton.isEnabled)
    }
}
