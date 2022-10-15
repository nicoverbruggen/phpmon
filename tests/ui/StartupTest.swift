//
//  UI_Tests.swift
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

    func testApplicationCanLaunchWithTestConfigurationAndIdles() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--configuration:working"]
        app.launch()
    }

    func testApplicationCanLaunchWithTestConfigurationAndThrowsAlert() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--configuration:broken"]
        app.launch()

        // Dialog 1: "PHP is not correctly installed"
        assertAllExist([
            app.dialogs["Notice"],
            app.staticTexts["PHP is not correctly installed"],
            app.buttons["OK"],
        ])
        click(app.buttons["OK"])

        // Dialog 2: PHP Monitor failed to start
        assertAllExist([
            app.dialogs["Notice"],
            app.staticTexts["PHP Monitor cannot start due to a problem with your system configuration"],
            app.buttons["Retry"],
            app.buttons["Quit"]
        ])
        click(app.buttons["Retry"])

        // Dialog 1 again
        assertExists(app.staticTexts["PHP is not correctly installed"])

        // At this point, we can terminate the test
        app.terminate()
    }
}
