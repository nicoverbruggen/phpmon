//
//  BytePhpPreferenceTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 04/09/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class BytePhpPreferenceTest: XCTestCase {

    func test_can_extract_memory_value() throws {
        let pref = BytePhpPreference(key: "memory_limit")

        XCTAssertEqual(pref.internalValue, "512M")
        XCTAssertEqual(pref.unit, .megabyte)
        XCTAssertEqual(pref.value, 512)
    }

    func test_can_parse_all_kinds_of_values() throws {
        var (unit, value) = BytePhpPreference.readFrom(internalValue: "1G")!
        XCTAssertEqual(unit, .gigabyte)
        XCTAssertEqual(value, 1)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "256M")!
        XCTAssertEqual(unit, .megabyte)
        XCTAssertEqual(value, 256)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "512K")!
        XCTAssertEqual(unit, .kilobyte)
        XCTAssertEqual(value, 512)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "1024")!
        XCTAssertEqual(unit, .kilobyte)
        XCTAssertEqual(value, 1024)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "-1")!
        XCTAssertEqual(unit, .kilobyte)
        XCTAssertEqual(value, -1)
    }
}
