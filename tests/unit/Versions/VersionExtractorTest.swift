//
//  VersionExtractorTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct VersionExtractorTest {
    @Test func test_extract_version() {
        #expect(VersionExtractor.from("Laravel Valet 2.17.1") == "2.17.1")
        #expect(VersionExtractor.from("Laravel Valet 2.0") == "2.0")
    }

    @Test func test_version_comparison() {
        #expect("2.0".versionCompare("2.1") == .orderedAscending)
        #expect("2.1".versionCompare("2.0") == .orderedDescending)
        #expect("2.0".versionCompare("2.0") == .orderedSame)
        #expect("2.17.0".versionCompare("2.17.1") == .orderedAscending)
    }
}
