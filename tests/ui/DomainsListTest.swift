//
//  StartupTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest

final class DomainsListTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    final func test_can_always_open_domains_list() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()
    }

    final func test_can_filter_domains_list() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        let searchField = window.searchFields.element(boundBy: 0)

        searchField.click()
        searchField.typeText("non-existent thing")
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(window.tables.tableRows.count == 0) // swiftlint:disable:this empty_count

        searchField.clearText()
        searchField.click()
        searchField.typeText("concord")
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(window.tables.tableRows.count == 1)

        sleep(1)
    }

    final func test_can_tap_add_domain_button() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        window.buttons["Add Link"].click()

        assertExists(app.staticTexts["selection.title".localized])
        assertExists(app.buttons["selection.create_link".localized])
        assertExists(app.buttons["selection.create_proxy".localized])
        assertExists(app.buttons["selection.cancel".localized])

        sleep(1)
    }
}
