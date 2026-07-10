//
//  DomainListContextMenuTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

/**
 Tests the domain list's right-click context menu: the offered actions for
 sites vs. proxies, and the copy-URL action's observable effect (the
 pasteboard, which the test runner can read directly).
 */
final class DomainListContextMenuTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    final func test_right_click_offers_site_and_proxy_actions() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)

        app.menuItems["mi_domain_list".localized(for: "en")].click()
        let window = app.windows.element(boundBy: 0)
        assertExists(window, 2.0)

        // Right-clicking a site row selects it and shows the site actions
        let siteRow = window.staticTexts["concord.test"]
        assertExists(siteRow, 5.0)
        siteRow.rightClick()

        assertExists(app.menuItems["domain_list.open_in_finder".localized(for: "en")], 2.0)
        assertExists(app.menuItems["domain_list.open_in_terminal".localized(for: "en")])
        assertExists(app.menuItems["domain_list.open_in_browser".localized(for: "en")])
        assertExists(app.menuItems["domain_list.copy_url".localized(for: "en")])
        // concord.test is not secured in the fake configuration
        assertExists(app.menuItems["domain_list.secure".localized(for: "en")])
        assertExists(app.menuItems["domain_list.favorite".localized(for: "en")])

        // The copy-URL action writes the site's URL to the pasteboard
        app.menuItems["domain_list.copy_url".localized(for: "en")].click()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "http://concord.test")

        // Proxies get their own, smaller set of actions
        let searchField = window.searchFields.element(boundBy: 0)
        searchField.click()
        searchField.typeText("mailgun")
        Thread.sleep(forTimeInterval: 0.3)

        let proxyRow = window.staticTexts["mailgun.test"]
        assertExists(proxyRow, 2.0)
        proxyRow.rightClick()

        assertExists(app.menuItems["domain_list.open_in_browser".localized(for: "en")], 2.0)
        assertExists(app.menuItems["domain_list.unproxy".localized(for: "en")])
        assertNotExists(app.menuItems["domain_list.open_in_finder".localized(for: "en")])

        app.typeKey(.escape, modifierFlags: [])
    }
}
