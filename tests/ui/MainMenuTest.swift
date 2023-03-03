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
            // "Switch to PHP 8.2 (php)" should be visible since it is aliased to `php`
            app.menuItems["\("mi_php_switch".localized) 8.2 (php)"],
            // "Switch to PHP 8.1" should be the non-disabled option
            app.menuItems["\("mi_php_switch".localized) 8.1 (php@8.1)"],
            // "Switch to PHP 8.0" should be the non-disabled option
            app.menuItems["\("mi_php_switch".localized) 8.0 (php@8.0)"],
            // We should see the about and quit items
            app.menuItems["mi_about".localized],
            app.menuItems["mi_quit".localized]
        ])

        sleep(2)
    }

    final func test_can_open_about() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_about".localized).click()
    }

    final func test_can_open_settings() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_preferences".localized).click()
    }

    final func test_can_quit_app() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_quit".localized).click()
    }

}
