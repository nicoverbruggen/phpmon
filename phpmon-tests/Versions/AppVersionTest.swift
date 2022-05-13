//
//  AppVersionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class AppVersionTest: XCTestCase {

    func testCanRetrieveInternalAppVersion() {
        XCTAssertNotNil(AppVersion.fromCurrentVersion())
    }

    func testCanParseNormalVersionString() {
        let version = AppVersion.from("1.0.0")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(nil, version?.build)
        XCTAssertEqual(nil, version?.suffix)
    }

    func testCanParseCaskVersionString() {
        let version = AppVersion.from("1.0.0_600")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual("600", version?.build)
        XCTAssertEqual(nil, version?.suffix)
    }

    func testCanParseDevVersionStringWithoutBuildNumber() {
        let version = AppVersion.from("1.0.0-dev")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual(nil, version?.build)
        XCTAssertEqual("dev", version?.suffix)
    }

    func testCanParseDevVersionStringWithBuildNumber() {
        let version = AppVersion.from("1.0.0-dev,870")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual("870", version?.build)
        XCTAssertEqual("dev", version?.suffix)
    }

    func testCanParseUnderscoresAsBuildSeparatorToo() {
        let version = AppVersion.from("1.0.0-dev_870")

        XCTAssertNotNil(version)
        XCTAssertEqual("1.0.0", version?.version)
        XCTAssertEqual("870", version?.build)
        XCTAssertEqual("dev", version?.suffix)
    }

}
