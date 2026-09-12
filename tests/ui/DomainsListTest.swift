//
//  StartupTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest
import AppKit

final class DomainsListTest: UITestCase {

    @MainActor final func test_can_always_open_domains_list() throws {
        let app = launch()
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")

        // Cover first opening, minimized, existing, closed, and another PHP Monitor window being open.
        for attempt in 0..<5 {
            finder.activate()
            let background = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"
            }, object: nil)
            XCTAssertEqual(XCTWaiter().wait(for: [background], timeout: 3), .completed)

            // Clicking through the foreground app avoids Xcode activating PHP Monitor first.
            let origin = finder.coordinate(withNormalizedOffset: .zero)
            let frame = finder.frame
            let status = app.statusItems.firstMatch.frame
            origin.withOffset(CGVector(dx: status.midX - frame.minX, dy: status.midY - frame.minY)).click()
            let item = app.menuItems["mi_domain_list".localized]
            assertExists(item, 2.0)
            let itemFrame = item.frame
            origin.withOffset(CGVector(dx: itemFrame.midX - frame.minX, dy: itemFrame.midY - frame.minY)).click()
            let window = app.windows["domain_list.title".localized]
            assertExists(window, 2.0)

            let foreground = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.state == .runningForeground
            }, object: nil)
            XCTAssertEqual(XCTWaiter().wait(for: [foreground], timeout: 3), .completed,
                           "Domains must activate PHP Monitor on opening attempt \(attempt)")

            if attempt == 0 {
                window.buttons[XCUIIdentifierMinimizeWindow].click()
                assertNotExists(window, 2.0)
            } else if attempt > 1 {
                // Focus Domains explicitly when another app window, such as Settings, is open.
                window.click()
                XCTAssertTrue(app.menuBars.menuBarItems["Window"].menuItems["Close"].isEnabled,
                              "The Domains window must be eligible for keyboard window actions")
                window.typeKey("w", modifierFlags: .command)
                let closed = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "exists == false"), object: window
                )
                XCTAssertEqual(XCTWaiter().wait(for: [closed], timeout: 2), .completed,
                               "Domains must close on opening attempt \(attempt)")
            }

            if attempt == 3 {
                app.statusItems.firstMatch.click()
                app.menuItems["mi_preferences".localized].click()
                let settings = app.windows
                    .containing(.button, identifier: "prefs.tabs.general".localized)
                    .firstMatch
                assertExists(settings, 2.0)
            }
        }
    }

    @MainActor final func test_can_filter_domains_list() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        let searchField = window.searchFields.element(boundBy: 0)

        searchField.click()
        searchField.typeText("non-existent thing")
        let emptyTable = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in window.tables.tableRows.count == 0 }, object: nil // swiftlint:disable:this empty_count
        )
        XCTAssertEqual(XCTWaiter().wait(for: [emptyTable], timeout: 2), .completed)

        searchField.clearText()
        searchField.click()
        searchField.typeText("concord")
        let filteredTable = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in window.tables.tableRows.count == 1 }, object: nil
        )
        XCTAssertEqual(XCTWaiter().wait(for: [filteredTable], timeout: 2), .completed)
    }

    @MainActor final func test_can_click_add_domain_button() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        window.buttons["Add Link"].click()

        assertExists(app.staticTexts["selection.title".localized])
        assertExists(app.buttons["selection.create_link".localized])
        assertExists(app.buttons["selection.create_proxy".localized])
        assertExists(app.buttons["selection.cancel".localized])
    }

    @MainActor final func test_can_open_create_link_view() throws {
        let app = launch(openMenu: true)

        app.menuItems["mi_domain_list".localized].click()

        let window = app.windows.element(boundBy: 0)
        XCTAssertEqual(window.title, "domain_list.title".localized)

        window.buttons["Add Link"].click()
        app.buttons["selection.create_link".localized].click()

        // Wait for NSOpenPanel, then use Go to Folder to choose /tmp.
        assertExists(app.sheets.firstMatch, 3.0)
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText("/tmp\n")
        app.typeKey(.return, modifierFlags: [])

        assertExists(app.staticTexts["domain_list.add.link_folder".localized])
        assertExists(app.buttons["domain_list.add.cancel".localized])
    }

    @MainActor final func test_can_open_create_proxy_view() throws {
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
    }
}
