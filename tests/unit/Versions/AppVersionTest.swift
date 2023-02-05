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

    func test_can_compare_version_numbers() {
        var first = AppVersion.from("5.0_100")!
        var second = AppVersion.from("5.0_101")!
        XCTAssertTrue(second > first)

        first = AppVersion.from("5.0_100")!
        second = AppVersion.from("5.0_100")!
        XCTAssertFalse(second > first)

        first = AppVersion.from("5.0_100")!
        second = AppVersion.from("5.0.1_100")!
        XCTAssertFalse(second > first)

        first = AppVersion.from("5.0_102")!
        second = AppVersion.from("5.0_101")!
        XCTAssertFalse(second > first)
    }

}
