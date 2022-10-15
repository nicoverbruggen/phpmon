//
//  UI_Tests.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

final class UI_Tests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    func testApplicationCanLaunchWithTestConfigurationAndIdles() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["--configuration:working"]
        app.launch()
        // XCTAssert(app.dialogs["Notice"].waitForExistence(timeout: 5))
        sleep(10)
    }

    func testApplicationCanLaunchWithTestConfigurationAndThrowsAlert() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["--configuration:broken"]
        app.launch()
        XCTAssert(app.dialogs["Notice"].waitForExistence(timeout: 5))
        app.buttons["OK"].click()
        XCTAssert(app.dialogs["Notice"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["Quit"].waitForExistence(timeout: 1))
        // If this UI test presses the "Quit" button, the test takes forever
        // because Xcode will attempt to figure out if the app closed correctly.
        app.terminate()
    }
}
