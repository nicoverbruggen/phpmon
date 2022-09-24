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

    func testTaggedReleaseOmitsZeroPatch() {
        let version = AppVersion.from("3.5.0_333")!

        XCTAssertEqual(version.tagged, "3.5")
        XCTAssertEqual(version.version, "3.5.0")
    }

    func testTaggedReleaseDoesntOmitNonZeroPatch() {
        let version = AppVersion.from("3.5.1_333")!

        XCTAssertEqual(version.tagged, "3.5.1")
        XCTAssertEqual(version.version, "3.5.1")
    }

    func testTagTruncationDoesntAffectMajorVersions() {
        var version = AppVersion.from("5.0_333")!

        XCTAssertEqual(version.tagged, "5.0")
        XCTAssertEqual(version.version, "5.0")

        version = AppVersion.from("5.0.0_333")!

        XCTAssertEqual(version.tagged, "5.0")
        XCTAssertEqual(version.version, "5.0.0")
    }

}
