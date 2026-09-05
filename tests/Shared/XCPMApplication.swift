//
//  XCPMApplication.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest

class XCPMApplication: XCUIApplication {
    override func launch() {
        precondition(
            launchEnvironment["PHPMON_TEST_CONFIGURATION"] != nil,
            "UI tests must provide a fake configuration before launching PHP Monitor."
        )
        super.launch()
    }

    public func withConfiguration(_ configuration: TestableConfiguration) {
        launchEnvironment["PHPMON_TEST_CONFIGURATION"] = configuration.toJson()
    }
}
