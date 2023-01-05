//
//  PhpVersionNumberTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

// swiftlint:disable type_body_length
class PhpVersionNumberTest: XCTestCase {

    func test_can_deconstruct_php_version() throws {
        XCTAssertEqual(
            try! VersionNumber.parse("PHP 8.2.0-dev"),
            VersionNumber(major: 8, minor: 2, patch: 0)
        )
        XCTAssertEqual(
            try! VersionNumber.parse("PHP 8.1.0RC5-dev"),
            VersionNumber(major: 8, minor: 1, patch: 0)
        )
        XCTAssertEqual(
            try! VersionNumber.parse("8.0.11"),
            VersionNumber(major: 8, minor: 0, patch: 11)
        )
        XCTAssertEqual(
            try! VersionNumber.parse("7.4.2"),
            VersionNumber(major: 7, minor: 4, patch: 2)
        )
        XCTAssertEqual(
            try! VersionNumber.parse("7.4"),
            VersionNumber(major: 7, minor: 4, patch: nil)
        )
        XCTAssertEqual(
            VersionNumber.make(from: "7"),
            nil
        )
    }

    func test_php_version_number_parse() throws {
        XCTAssertThrowsError(try VersionNumber.parse("OOF")) { error in
            XCTAssertTrue(error is VersionParseError)
        }
    }

    func test_can_check_fixed_constraints() throws {
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "7.0"),
            PhpVersionNumberCollection
                .make(from: ["7.0"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.3", "7.3.3", "7.2.3", "7.1.3", "7.0.3"])
                .matching(constraint: "7.0.3"),
            PhpVersionNumberCollection
                .make(from: ["7.0.3"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "7.0.3", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.0"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "7.0.3", strict: true),
            PhpVersionNumberCollection
                .make(from: []).all
        )
    }

    func test_can_check_caret_constraints() throws {
        // 1. Imprecise checks
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "^7.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"]).all
        )

        // 2. Imprecise check with precise constraint (lenient AKA not strict)
        // These versions are interpreted as 7.4.999, 7.3.999, 7.2.999, etc.
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "^7.0.1", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"]).all
        )

        // 3. Imprecise check with precise constraint (strict mode)
        // These versions are interpreted as 7.4.0, 7.3.0, 7.2.0, etc.
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "^7.0.1", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1"]).all
        )

        // 4. Precise members and constraint all around
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "^7.0.1", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"]).all
        )

        // 5. Precise members but imprecise constraint (strict mode)
        // In strict mode the constraint's patch version is assumed to be 0
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "^7.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"]).all
        )

        // 6. Precise members but imprecise constraint (lenient mode)
        // In lenient mode the constraint's patch version is assumed to be equal
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "^7.0", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"]).all
        )
    }

    func test_can_check_tilde_constraints() throws {
        // 1. Imprecise checks
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "~7.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"]).all
        )

        // 2. Imprecise check with precise constraint (lenient AKA not strict)
        // These versions are interpreted as 7.4.999, 7.3.999, 7.2.999, etc.
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "~7.0.1", strict: false),
            // One result because 7.0.1 to 7.0.x is expected.
            // 7.0.999 (assumed due to no strictness) is valid.
            // 7.1.0 and up are not valid (minor version is too high).
            PhpVersionNumberCollection
                .make(from: ["7.0"]).all
        )

        // 3. Imprecise check with precise constraint (strict mode)
        // These versions are interpreted as 7.4.0, 7.3.0, 7.2.0, etc.
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "~7.0.1", strict: true),
            // No results because 7.0.1 to 7.0.x is expected.
            // 7.0.0 (assumed due to strictness) is not valid.
            // 7.1.0 and up are also not valid (minor version is too high).
            PhpVersionNumberCollection
                .make(from: []).all
        )

        // 4. Precise members and constraint all around
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "~7.0.1", strict: true),
            // Only 7.0 with a patch version of .1 or higher is OK.
            // In this example, 7.0.10 is OK but all other versions are too new.
            PhpVersionNumberCollection
                .make(from: ["7.0.10"]).all
        )

        // 5. Precise members but imprecise constraint (strict mode)
        // In strict mode the constraint's patch version is assumed to be 0.
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "~7.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"]).all
        )

        // 6. Precise members but imprecise constraint (lenient mode)
        // In lenient mode the constraint's patch version is assumed to be equal.
        // (Strictness does not make any difference here, but both should be tested.)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"])
                .matching(constraint: "~7.0", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.4.10", "7.3.10", "7.2.10", "7.1.10", "7.0.10"]).all
        )
    }

    func test_can_check_greater_than_or_equal_constraints() throws {
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">=7.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">=7.0.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"]).all
        )

        // Strict check (>7.2.5 is too new for 7.2 which resolves to 7.2.0)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">=7.2.5", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3"]).all
        )

        // Non-strict check (ignoring patch, 7.2 resolves to 7.2.999)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">=7.2.5", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2"]).all
        )
    }

    func test_can_check_greater_than_constraints() throws {
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">7.0"),
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">7.2.5"),
            // 7.2 will be valid due to non-strict mode (resolves to 7.2.999)
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: ">7.2.5", strict: true),
            // 7.2 will not be valid due to strict mode (resolves to 7.2.0)
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.3.1", "7.2.9", "7.2.8", "7.2.6", "7.2.5", "7.2"])
                .matching(constraint: ">7.2.8"),
            // 7.2 will be valid due to non-strict mode (resolves to 7.2.999)
            PhpVersionNumberCollection
                .make(from: ["7.3.1", "7.2.9", "7.2"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.3.1", "7.2.9", "7.2.8", "7.2.6", "7.2.5", "7.2"])
                .matching(constraint: ">7.2.8", strict: true),
            // 7.2 will not be valid due to strict mode (resolves to 7.2.0)
            PhpVersionNumberCollection
                .make(from: ["7.3.1", "7.2.9"]).all
        )
    }

    func test_can_check_less_than_or_equal_constraints() throws {
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<=7.2", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.2", "7.1", "7.0"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<=7.2.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.2", "7.1", "7.0"]).all
        )

        // Strict check (>7.2.5 is too new for 7.2 which resolves to 7.2.0)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<=7.2.5", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.2", "7.1", "7.0"]).all
        )

        // Non-strict check (ignoring patch has no effect)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<=7.2.5", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.2", "7.1", "7.0"]).all
        )
    }

    func test_can_check_less_than_constraints() throws {
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<7.2", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.1", "7.0"]).all
        )

        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<7.2.0", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.1", "7.0"]).all
        )

        // Strict check (>7.2.5 is too new for 7.2 which resolves to 7.2.0)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<7.2.5", strict: true),
            PhpVersionNumberCollection
                .make(from: ["7.2", "7.1", "7.0"]).all
        )

        // Non-strict check (patch resolves to 7.2.999, which is bigger than 7.2.5)
        XCTAssertEqual(
            PhpVersionNumberCollection
                .make(from: ["7.4", "7.3", "7.2", "7.1", "7.0"])
                .matching(constraint: "<7.2.5", strict: false),
            PhpVersionNumberCollection
                .make(from: ["7.1", "7.0"]).all
        )
    }
}
