//
//  MainMenuHealthTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

final class MainMenuHealthTest: UITestCase {
    @MainActor func test_unparseable_active_php_shows_the_recovery_menu() {
        var configuration = configurationForHealthTests()
        configuration.commandOutput["/opt/homebrew/bin/php-config --version"] = "not a version"
        let app = launch(openMenu: true, with: configuration)

        assertExists(app.mainMenuItem(withText: "mi_php_broken_1".localized), 2)
        XCTAssertTrue(app.mainMenuItem(withText: "\("mi_php_switch".localized) 8.3 (php@8.3)").isEnabled)
        assertExists(app.mainMenuItem(withText: "mi_php_version_manager".localized), 2)
        attachHealthScreenshot(app, named: "Recovery menu for unparseable active PHP")
    }

    @MainActor func test_active_php_breaks_while_the_menu_is_open() {
        var configuration = configurationForHealthTests()
        let notificationName = "com.phpmon.tests.active-installation-change.\(UUID().uuidString)"
        configuration.phpInstallationChange = .init(
            notificationName: notificationName,
            commandOutputs: [
                "/opt/homebrew/bin/php-config --version": "not a version",
                "/opt/homebrew/opt/php@8.4/bin/php-config --version": "not a version",
                "/opt/homebrew/opt/php/bin/php-config --version": "not a version"
            ]
        )
        let app = launch(openMenu: true, with: configuration)

        let refreshed = expectation(description: "Active installation health refresh completed")
        let notifications = DistributedNotificationCenter.default()
        let observer = notifications.addObserver(
            forName: Notification.Name(notificationName + ".completed"), object: nil, queue: .main
        ) { _ in refreshed.fulfill() }
        defer { notifications.removeObserver(observer) }
        notifications.postNotificationName(
            Notification.Name(notificationName), object: nil, userInfo: nil, deliverImmediately: true
        )
        wait(for: [refreshed], timeout: 10)

        app.typeKey(.escape, modifierFlags: [])
        app.statusItems.firstMatch.click()
        assertExists(app.mainMenuItem(withText: "mi_php_broken_1".localized), 2)
        XCTAssertTrue(app.mainMenuItem(withText: "\("mi_php_switch".localized) 8.3 (php@8.3)").isEnabled)
        app.mainMenuItem(withText: "mi_php_version_manager".localized).click()
        assertExists(app.staticTexts["phpman.version.broken".localized], 10)
        assertExists(app.buttons["phpman.buttons.repair".localized], 2)
        attachHealthScreenshot(app.windows.firstMatch, named: "Repair remains available after active PHP breaks")
    }

    @MainActor func test_malformed_installed_php_is_available_for_repair() {
        var configuration = configurationForHealthTests()
        configuration.commandOutput["/opt/homebrew/opt/php@8.3/bin/php-config --version"] = "not a version"
        let app = launch(openMenu: true, with: configuration)

        app.mainMenuItem(withText: "\("mi_php_switch".localized) 8.3 (php@8.3)").click()
        assertExists(app.staticTexts["alert.php_switch_unhealthy.title".localized("8.3")], 2)
        XCTAssertLessThan(
            app.buttons["generic.cancel".localized].frame.minX,
            app.staticTexts["alert.php_switch_unhealthy.title".localized("8.3")].frame.minX
        )
        attachHealthScreenshot(app, named: "Unhealthy PHP switch alert")
        app.buttons["generic.cancel".localized].click()
        app.statusItems.firstMatch.click()
        XCTAssertFalse(app.mainMenuItem(withText: "\("mi_php_switch".localized) 8.4 (php)").isEnabled)
        app.mainMenuItem(withText: "mi_php_version_manager".localized).click()
        assertExists(app.staticTexts["phpman.version.broken".localized], 10)
        assertExists(app.buttons["phpman.buttons.repair".localized], 2)
        attachHealthScreenshot(app.windows.firstMatch, named: "Malformed PHP installation remains available for repair")
    }

    @MainActor func test_installation_breaks_while_status_menu_is_open() {
        var configuration = configurationForHealthTests()
        let notificationName = "com.phpmon.tests.installation-change.\(UUID().uuidString)"
        configuration.phpInstallationChange = .init(
            notificationName: notificationName,
            commandOutputs: ["/opt/homebrew/opt/php@8.3/bin/php-config --version": "not a version"]
        )
        let app = launch(openMenu: true, with: configuration)
        let switchTitle = "\("mi_php_switch".localized) 8.3 (php@8.3)"
        XCTAssertTrue(app.mainMenuItem(withText: switchTitle).isEnabled)
        let switchFrame = app.mainMenuItem(withText: switchTitle).frame
        XCTAssertGreaterThan(switchFrame.width, 0)
        let statusFrame = app.statusItems.firstMatch.frame
        let switchOffset = CGVector(dx: switchFrame.midX - statusFrame.minX, dy: switchFrame.midY - statusFrame.minY)
        attachHealthScreenshot(app, named: "Before PHP installation breaks")

        let refreshed = expectation(description: "Installation health refresh completed")
        let notifications = DistributedNotificationCenter.default()
        let observer = notifications.addObserver(
            forName: Notification.Name(notificationName + ".completed"), object: nil, queue: .main
        ) { _ in refreshed.fulfill() }
        defer { notifications.removeObserver(observer) }

        notifications.postNotificationName(
            Notification.Name(notificationName), object: nil, userInfo: nil, deliverImmediately: true
        )
        wait(for: [refreshed], timeout: 10)

        // Exercise refresh during menu tracking, without dismissing the menu first.
        assertExists(app.mainMenuItem(withText: "mi_php_version_manager".localized), 2)
        attachHealthScreenshot(app, named: "Open menu after PHP installation becomes unhealthy")
        let switchItem = app.mainMenuItem(withText: switchTitle)
        let menuState = XCTAttachment(string: "Enabled after health refresh: \(switchItem.isEnabled)\n\(switchItem.debugDescription)")
        menuState.name = "Switch item after health refresh"
        menuState.lifetime = .keepAlways
        add(menuState)

        // Click the item that is still on screen. Accessibility now describes the
        // replacement menu, whose items have no screen coordinates until it opens.
        app.statusItems.firstMatch.coordinate(withNormalizedOffset: .zero).withOffset(switchOffset).click()
        assertExists(app.staticTexts["alert.php_switch_unhealthy.title".localized("8.3")], 2)
        app.buttons["alert.php_switch_unhealthy.repair".localized].click()
        assertExists(app.staticTexts["phpman.version.broken".localized], 10)
        assertExists(app.buttons["phpman.buttons.repair".localized], 2)
        attachHealthScreenshot(app.windows.firstMatch, named: "PHP version manager offers repair after the background refresh")
    }

    @MainActor private func configurationForHealthTests() -> TestableConfiguration {
        var configuration = TestableConfigurations.working
        let taps = "shivammathur/php\nshivammathur/extensions"
        configuration.shellOutput["/opt/homebrew/bin/brew tap"] = .instant(taps)
        configuration.shellOutput["/opt/homebrew/bin/brew trust --tap"] = .instant(taps)
        return configuration
    }

    @MainActor private func attachHealthScreenshot(_ element: XCUIElement, named name: String) {
        let screenshot = XCTAttachment(screenshot: element.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
