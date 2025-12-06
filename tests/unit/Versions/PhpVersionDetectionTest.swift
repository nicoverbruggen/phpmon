//
//  PhpVersionDetectionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct PhpVersionDetectionTest {
    @Test func test_can_detect_valid_php_versions() async throws {
        let container = Container.real()

        let versions = await container.phpEnvs.extractPhpVersions(
            from: [
                "", // empty lines should be omitted
                "php@8.0",
                "php@8.0", // should only be detected once
                "meta-php@8.0", // should be omitted, invalid
                "php@8.0-coolio", // should be omitted, invalid
                "php@7.0",
                "",
                "unrelatedphp@1.0", // should be omitted, invalid
                "php@5.6", // should be omitted, not supported
                "php@5.4" // should be omitted, not supported
            ],
            checkBinaries: false,
            generateHelpers: false
        )

        #expect(versions == ["8.0", "7.0", "5.6"])
    }
}
