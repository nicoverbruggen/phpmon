//
//  PhpConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class PhpConfigurationTest: XCTestCase {

    static var phpIniFileUrl: URL {
        return Bundle(for: Self.self).url(forResource: "php", withExtension: "ini")!
    }

    func testCanLoadExtension() throws {
        let iniFile = PhpConfigurationFile.from(filePath: Self.phpIniFileUrl.path)!

        XCTAssertNotNil(iniFile)

        XCTAssertGreaterThan(iniFile.extensions.count, 0)
    }

    func testCanCheckKeyExistence() throws {
        let iniFile = PhpConfigurationFile.from(filePath: Self.phpIniFileUrl.path)!

        XCTAssertTrue(iniFile.has(key: "error_reporting"))
        XCTAssertTrue(iniFile.has(key: "display_errors"))
        XCTAssertFalse(iniFile.has(key: "my_unknown_key"))
    }

    func testCanCheckKeyValue() throws {
        let iniFile = PhpConfigurationFile.from(filePath: Self.phpIniFileUrl.path)!

        XCTAssertNotNil(iniFile.get(for: "error_reporting"))
        XCTAssert(iniFile.get(for: "error_reporting") == "E_ALL")

        XCTAssertNotNil(iniFile.get(for: "display_errors"))
        XCTAssert(iniFile.get(for: "display_errors") == "On")
    }

    func testCanCustomizeConfigurationValue() throws {
        let destination = Utility
            .copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!

        let configurationFile = PhpConfigurationFile
            .from(filePath: destination.path)!

        // 0. Verify the original value
        XCTAssertEqual(configurationFile.get(for: "error_reporting"), "E_ALL")

        // 1. Change the value
        try! configurationFile.replace(
            key: "error_reporting",
            value: "E_ALL & ~E_DEPRECATED & ~E_STRICT"
        )
        XCTAssertEqual(
            configurationFile.get(for: "error_reporting"),
            "E_ALL & ~E_DEPRECATED & ~E_STRICT"
        )

        // 2. Ensure that same key and value doesn't break subsequent saves
        try! configurationFile.replace(
            key: "error_reporting",
            value: "error_reporting"
        )
        XCTAssertEqual(
            configurationFile.get(for: "error_reporting"),
            "error_reporting"
        )

        // 3. Verify subsequent saves weren't broken
        try! configurationFile.replace(
            key: "error_reporting",
            value: "E_ALL"
        )
        XCTAssertEqual(
            configurationFile.get(for: "error_reporting"),
            "E_ALL"
        )
    }

}
