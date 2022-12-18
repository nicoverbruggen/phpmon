//
//  StartupTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

final class DomainsListTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    private func openMenu() -> XCPMApplication {
        let app = XCPMApplication()
        app.withConfiguration(TestableConfigurations.working)
        app.launch()

        // Note: If this fails here, make sure the menu bar item can be displayed
        // If you use Bartender or something like this, this item may be hidden and tests will fail
        app.statusItems.firstMatch.click()

        return app
    }

    final func test_can_always_open_domains_list() throws {
        let app = openMenu()

        app.menuItems["mi_domain_list".localized].click()
    }

    final func test_can_filter_domains_list() throws {
        let app = openMenu()

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.allElementsBoundByIndex.first { element in
            element.title == "domain_list.title".localized
        }!

        let searchField = window.searchFields.firstMatch

        searchField.click()
        searchField.typeText("non-existent thing")
        XCTAssertTrue(window.tables.tableRows.count == 0)

        searchField.clearText()
        searchField.click()
        searchField.typeText("concord")
        XCTAssertTrue(window.tables.tableRows.count == 1)

        sleep(2)
    }

    final func test_can_tap_add_domain_button() throws {
        let app = openMenu()

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.allElementsBoundByIndex.first { element in
            element.title == "domain_list.title".localized
        }!

        window.buttons["Add Link"].click()

        assertExists(app.staticTexts["selection.title".localized])
        assertExists(app.buttons["selection.create_link".localized])
        assertExists(app.buttons["selection.create_proxy".localized])
        assertExists(app.buttons["selection.cancel".localized])

        sleep(2)
    }
}
