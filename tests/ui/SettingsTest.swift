//
//  SettingsTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

final class SettingsTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    final func test_changing_language_closes_other_windows() throws {
        let app = launch(openMenu: true)

        // First, open the domains window
        app.mainMenuItem(withText: "mi_domain_list".localized).click()
        let domainsWindow = app.windows["domain_list.title".localized]
        assertExists(domainsWindow, 2.0)

        // Press the menu button again
        app.statusItems.firstMatch.click() // press the menu button again

        // This time, open the preferences window
        app.mainMenuItem(withText: "mi_preferences".localized).click()
        let settingsWindow = app.windows
            .containing(.button, identifier: "prefs.tabs.general".localized(for: "en"))
            .firstMatch
        assertExists(settingsWindow, 2.0)
        assertExists(app.buttons["prefs.tabs.general".localized(for: "en")], 2.0)

        // In the languages pop-up, click on it
        let languagePopup = settingsWindow.popUpButtons.element(boundBy: 0)
        languagePopup.click()
        languagePopup.menuItems["Japanese"].click()
        assertNotExists(domainsWindow, 2.0)
        assertNotExists(settingsWindow, 2.0)

        // Find the Japanese language settings window now
        let settingsWindowJa = app.windows
            .containing(.button, identifier: "prefs.tabs.general".localized(for: "ja"))
            .firstMatch
        assertExists(settingsWindowJa, 2.0)
        assertExists(app.buttons["prefs.tabs.general".localized(for: "ja")], 2.0)
        assertExists(settingsWindowJa.staticTexts["prefs.language".localized(for: "ja")], 2.0)

        // Switch back to the original language
        let resetPopup = settingsWindowJa.popUpButtons.element(boundBy: 0)
        resetPopup.click()
        resetPopup.menuItems["System Default"].click()
    }
}
