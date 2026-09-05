//
//  MainMenuBarTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

/**
 Tests the app's main menu bar (built in code via `AppMenu.build`) — not the
 status bar menu, which `MainMenuTest` covers.

 Note: because the app starts as an accessory and only gains a menu bar when a
 window opens, XCUITest exposes the menu bar's *hierarchy* but reports its
 items as non-hittable. The structure and enabled states are therefore asserted
 via queries, and the menu actions are triggered through their key equivalents
 (which are routed through the main menu, exercising the same wiring).
 */
final class MainMenuBarTest: UITestCase {

    final func test_main_menu_bar_offers_site_actions() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)

        // Open the domains window: the app switches to a regular activation
        // policy and receives a main menu bar.
        app.menuItems["mi_domain_list".localized(for: "en")].click()

        let window = app.windows.element(boundBy: 0)
        assertExists(window, 2.0)
        XCTAssertEqual(window.title, "domain_list.title".localized(for: "en"))

        app.activate()
        window.click()

        // The top-level menus are present. (The "Help" item exists in the main
        // menu but has no submenu — matching the old storyboard — so it is not
        // rendered into the menu bar's accessibility hierarchy.)
        let sites = app.menuBars.menuBarItems["Sites"]
        assertExists(sites, 5.0)
        assertExists(app.menuBars.menuBarItems[app.title])
        assertExists(app.menuBars.menuBarItems["Edit"])
        assertExists(app.menuBars.menuBarItems["Window"])

        // The Sites menu contains the expected items
        assertExists(sites.menuItems["mm_add_folder_as_link".localized(for: "en")])
        assertExists(sites.menuItems["mm_reload_domain_list".localized(for: "en")])
        assertExists(sites.menuItems["mm_find_in_domain_list".localized(for: "en")])

        // Without a selection, the Actions item is disabled
        let actions = sites.menuItems["mm_actions".localized(for: "en")]
        assertExists(actions, 2.0)
        XCTAssertFalse(actions.isEnabled)

        // Selecting a site fills the Actions item with that site's submenu
        window.staticTexts["concord.test"].click()
        let actionsForSite = sites.menuItems["mm_actions".localized(for: "en") + " (concord.test)"]
        assertExists(actionsForSite, 2.0)
        XCTAssertTrue(actionsForSite.isEnabled)

        // ⌘F (the find menu item) focuses the search field, so typing filters
        app.typeKey("f", modifierFlags: .command)
        app.typeText("concord")
        let searchField = window.searchFields.element(boundBy: 0)
        XCTAssertEqual(searchField.value as? String, "concord")
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(window.tables.tableRows.count == 1)

        // ⌘N (the add-link menu item) opens the domain type selection sheet
        app.typeKey("n", modifierFlags: .command)
        assertExists(app.staticTexts["selection.title".localized(for: "en")], 2.0)
    }
}
