//
//  MainMenuTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 03/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

final class MainMenuTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    final func test_can_open_status_menu_item() throws {
        let app = launch(openMenu: true)

        assertAllExist([
            // "Switch to PHP 8.4 (php)" should be visible since it is aliased to `php`
            app.menuItems["\("mi_php_switch".localized) 8.4 (php)"],
            // "Switch to PHP 8.1" should be the non-disabled option
            app.menuItems["\("mi_php_switch".localized) 8.3 (php@8.3)"],
            app.menuItems["\("mi_php_switch".localized) 8.2 (php@8.2)"],
            app.menuItems["\("mi_php_switch".localized) 8.1 (php@8.1)"],
            app.menuItems["\("mi_php_switch".localized) 8.0 (php@8.0)"],
            // We should see the about and quit items
            app.menuItems["mi_about".localized],
            app.menuItems["mi_quit".localized]
        ])

        sleep(2)
    }

    final func test_can_open_domains_list() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_domain_list".localized).click()
    }

    final func test_can_open_php_doctor() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).click()
        app.mainMenuItem(withText: "mi_fa_php_doctor".localized).click()
    }

    final func test_can_view_onboarding_flow() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).click()
        app.mainMenuItem(withText: "mi_view_onboarding".localized).click()
    }

    final func test_can_open_about() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_about".localized).click()
    }

    final func test_can_open_config_editor() throws {
        let app = launch(openMenu: true)

        app.buttons["phpConfigButton"].click()

        Thread.sleep(forTimeInterval: 0.5)

        assertExists(app.staticTexts["confman.title".localized], 1)
    }

    final func test_can_open_settings() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_preferences".localized).click()

        Thread.sleep(forTimeInterval: 0.5)

        assertExists(app.buttons["General"])
        click(app.buttons["General"])

        assertExists(app.buttons["Appearance"])
        click(app.buttons["Appearance"])

        assertExists(app.buttons["Visibility"])
        click(app.buttons["Visibility"])

        assertExists(app.buttons["Notifications"])
        click(app.buttons["Notifications"])
    }

    final func test_can_open_php_version_manager() throws {
        let app = launch(openMenu: true)

        app.mainMenuItem(withText: "mi_php_version_manager".localized).click()

        // Should display loader
        assertExists(app.staticTexts["phpman.busy.title".localized], 1)

        // After loading, should display PHP 8.2, PHP 8.3, PHP 8.4
        assertExists(app.staticTexts["PHP 8.2"], 5)
        assertExists(app.staticTexts["PHP 8.3"])
        assertExists(app.staticTexts["PHP 8.4"])

        // Should also display pre-release version
        assertExists(app.staticTexts["PHP 8.5"])
        assertExists(app.staticTexts["phpman.version.prerelease".localized.uppercased()])
        assertExists(app.staticTexts["phpman.version.available_for_installation".localized])

        // The pre-release version should be unavailable
        assertExists(app.staticTexts["phpman.version.unavailable".localized])

        // But not PHP 8.6 (yet)
        assertNotExists(app.staticTexts["PHP 8.6"])

        // Also, PHP 8.2 should have an update available
        assertExists(app.staticTexts["phpman.version.has_update".localized(
            "8.2.6",
            "8.2.11"
        )], 5)
    }

    final func test_can_quit_app() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_quit".localized).click()
    }

}
