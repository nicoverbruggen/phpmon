//
//  AppUpdaterCheckTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class AppUpdaterCheckTest: XCTestCase {

    func test_can_retrieve_version_from_cask() async {
        let caskVersion = await AppUpdateChecker.retrieveVersionFromCask()

        let version = VersionExtractor.from(caskVersion)

        XCTAssertNotNil(version)
    }

    func test_tagged_release_omits_zero_patch() {
        let version = AppVersion.from("3.5.0_333")!

        XCTAssertEqual(version.tagged, "3.5")
        XCTAssertEqual(version.version, "3.5.0")
    }

    func test_tagged_release_doesnt_omit_non_zero_patch() {
        let version = AppVersion.from("3.5.1_333")!

        XCTAssertEqual(version.tagged, "3.5.1")
        XCTAssertEqual(version.version, "3.5.1")
    }

    func test_tag_truncation_does_not_affect_major_versions() {
        var version = AppVersion.from("5.0_333")!

        XCTAssertEqual(version.tagged, "5.0")
        XCTAssertEqual(version.version, "5.0")

        version = AppVersion.from("5.0.0_333")!

        XCTAssertEqual(version.tagged, "5.0")
        XCTAssertEqual(version.version, "5.0.0")
    }

}
