//
//  BytePhpPreferenceTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 04/09/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing

struct BytePhpPreferenceTest {
    @Test func test_can_extract_memory_value() throws {
        let pref = BytePhpPreference(key: "memory_limit")

        #expect(pref.internalValue == "512M")
        #expect(pref.unit == .megabyte)
        #expect(pref.value == 512)
    }

    @Test func test_can_parse_all_kinds_of_values() throws {
        var (unit, value) = BytePhpPreference.readFrom(internalValue: "1G")!
        #expect(unit == .gigabyte)
        #expect(value == 1)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "256M")!
        #expect(unit == .megabyte)
        #expect(value == 256)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "512K")!
        #expect(unit == .kilobyte)
        #expect(value == 512)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "1024")!
        #expect(unit == .kilobyte)
        #expect(value == 1024)

        (unit, value) = BytePhpPreference.readFrom(internalValue: "-1")!
        #expect(unit == .kilobyte)
        #expect(value == -1)
    }
}
