//
//  StartupTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

final class StartupTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    func testApplicationCanLaunchWithTestConfigurationAndThrowsAlert() throws {
        var configuration = TestableConfigurations.working
        configuration.filesystem["/opt/homebrew/bin/php"] = nil // PHP binary must be missing

        let app = XCPMApplication()
        app.withConfiguration(configuration)
        app.launch()

        // Dialog 1: "PHP is not correctly installed"
        assertAllExist([
            app.dialogs["generic.notice".localized],
            app.staticTexts["startup.errors.php_binary.title".localized],
            app.buttons["generic.ok".localized],
        ])
        click(app.buttons["generic.ok".localized])

        // Dialog 2: PHP Monitor failed to start
        assertAllExist([
            app.dialogs["generic.notice".localized],
            app.staticTexts["alert.cannot_start.title".localized],
            app.buttons["alert.cannot_start.retry".localized],
            app.buttons["alert.cannot_start.close".localized]
        ])
        click(app.buttons["alert.cannot_start.retry".localized])

        // Dialog 1 again
        assertExists(app.staticTexts["startup.errors.php_binary.title".localized])

        // At this point, we can terminate the test
        app.terminate()
    }

    func testApplicationCanWarnAboutPhpFpmIssue() throws {
        var configuration = TestableConfigurations.working
        configuration.filesystem["/opt/homebrew/etc/php/8.1/php-fpm.d/valet-fpm.conf"] = nil

        let app = XCPMApplication()
        app.withConfiguration(configuration)
        app.launch()

        assertExists(app.staticTexts["alert.php_fpm_broken.title".localized], 3.0)
        click(app.buttons["generic.ok".localized])
    }

    func testApplicationCanLaunchWithTestConfigurationAndCanClickMenuItem() throws {
        let app = XCPMApplication()
        app.withConfiguration(TestableConfigurations.working)
        app.launch()

        // Note: If this fails here, make sure the menu bar item can be displayed
        // If you use Bartender or something like this, this item may be hidden and tests will fail
        let statusBarItem = app.statusItems.firstMatch
        statusBarItem.click()
        assertAllExist([
            app.menuItems["mi_about".localized],
            app.menuItems["mi_quit".localized]
        ])
    }
}
