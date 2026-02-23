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

    /**
     In this test, we start with the app configured with the English override.
     After opening the domains window, we switch to Japanese.
     */
    final func test_changing_language_closes_other_windows() throws {
        var configuration = TestableConfigurations.working

        // Our default starting point is to use the system default language
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)

        // First, open the domains window
        app.mainMenuItem(withText: "mi_domain_list".localized(for: "en")).click()
        let domainsWindow = app.windows["domain_list.title".localized(for: "en")]
        assertExists(domainsWindow, 2.0)

        // Press the menu button again
        app.statusItems.firstMatch.click()

        // This time, open the preferences window
        app.mainMenuItem(withText: "mi_preferences".localized).click()
        let settingsWindow = app.windows
            .containing(.button, identifier: "prefs.tabs.general".localized(for: "en"))
            .firstMatch
        assertExists(settingsWindow, 2.0)
        assertExists(app.buttons["prefs.tabs.general".localized(for: "en")])

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
        assertExists(app.buttons["prefs.tabs.general".localized(for: "ja")])
        assertExists(settingsWindowJa.staticTexts["prefs.language".localized(for: "ja")])

        // Open the domains window
        app.statusItems.firstMatch.click()
        app.mainMenuItem(withText: "mi_domain_list".localized(for: "ja")).click()
        let domainsWindowJa = app.windows["domain_list.title".localized(for: "ja")]
        assertExists(domainsWindowJa, 2.0)

        // Verify the localized placeholder text ("Search") exists
        let searchField = domainsWindowJa.searchFields.element(boundBy: 0)
        assertExists(searchField, 2.0)
        XCTAssertEqual(searchField.placeholderValue, "generic.search".localized(for: "ja"))

        // Switch back to English
        let resetPopup = settingsWindowJa.popUpButtons.element(boundBy: 0)
        resetPopup.click()
        resetPopup.menuItems["English"].click()
    }
}
