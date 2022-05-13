//
//  AppUpdaterCheckTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class AppUpdaterCheckTest: XCTestCase {

    func testCanRetrieveVersionFromCask() {
        let caskVersion = AppUpdateChecker.retrieveVersionFromCask()

        let version = VersionExtractor.from(caskVersion)

        XCTAssertNotNil(version)
    }

}
