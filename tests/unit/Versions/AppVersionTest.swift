//
//  AppVersionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class AppVersionTest: XCTestCase {

    func test_can_retrieve_internal_app_version() {
        XCTAssertNotNil(AppVersion.fromCurrentVersion())
    }

    func test_can_parse_normal_version_string() {
        let version = AppVersion.from("1.0.0")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(nil, version?.build)
        XCTAssertEqual(nil, version?.suffix)
    }

    func test_can_parse_cask_version_string() {
        let version = AppVersion.from("1.0.0_600")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(600, version?.build)
        XCTAssertEqual(nil, version?.suffix)
    }

    func test_can_parse_dev_version_string_without_build_number() {
        let version = AppVersion.from("1.0.0-dev")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(nil, version?.build)
        XCTAssertEqual("dev", version?.suffix)
    }

    func test_can_parse_dev_version_string_with_build_number() {
        let version = AppVersion.from("1.0.0-dev,870")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(870, version?.build)
        XCTAssertEqual("dev", version?.suffix)
    }

    func test_can_parse_underscores_as_build_separator() {
        let version = AppVersion.from("1.0.0-dev_870")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(870, version?.build)
        XCTAssertEqual("dev", version?.suffix)
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

    func test_can_compare_version_numbers() {
        // Build is newer
        XCTAssertTrue(AppVersion.from("5.0_101")! > AppVersion.from("5.0_100")!)

        // Version and build is the same
        XCTAssertFalse(AppVersion.from("5.0.0_100")! > AppVersion.from("5.0_100")!)

        // Version is newer
        XCTAssertTrue(AppVersion.from("5.1_100")! > AppVersion.from("5.0_100")!)

        // Build is older
        XCTAssertFalse(AppVersion.from("5.0_101")! > AppVersion.from("5.0_102")!)
    }

}
