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

    final func test_can_click_add_domain_button() throws {
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

    final func test_can_open_create_link_view() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        window.buttons["Add Link"].click()
        app.buttons["selection.create_link".localized].click()

        // NSOpenPanel opens as a sheet — use Go to Folder to navigate to /tmp and confirm
        Thread.sleep(forTimeInterval: 0.3)
        app.typeKey("g", modifierFlags: [.command, .shift])
        Thread.sleep(forTimeInterval: 0.2)
        app.typeText("/tmp\n")
        Thread.sleep(forTimeInterval: 0.2)
        app.typeKey(.return, modifierFlags: [])

        assertExists(app.staticTexts["domain_list.add.link_folder".localized])
        assertExists(app.buttons["domain_list.add.cancel".localized])

        sleep(1)
    }

    final func test_can_open_create_proxy_view() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        window.buttons["Add Link"].click()
        app.buttons["selection.create_proxy".localized].click()

        assertExists(app.staticTexts["domain_list.add.set_up_proxy".localized])
        assertExists(app.staticTexts["domain_list.add.proxy_subject".localized])
        assertExists(app.staticTexts["domain_list.add.domain_name".localized])
        assertExists(app.buttons["domain_list.add.cancel".localized])

        sleep(1)
    }
}
