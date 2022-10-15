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
        sleep(10)
    }
}
