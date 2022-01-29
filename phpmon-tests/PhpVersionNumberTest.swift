//
//  PhpVersionNumberTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class PhpVersionNumberTest: XCTestCase {

    func testCanDeconstructPhpVersion() throws {
        XCTAssertEqual(
            PhpVersionNumber.make(from: "8.0.11"),
            PhpVersionNumber(major: 8, minor: 0, patch: 11)
        )
        XCTAssertEqual(
            PhpVersionNumber.make(from: "7.4.2"),
            PhpVersionNumber(major: 7, minor: 4, patch: 2)
        )
        XCTAssertEqual(
            PhpVersionNumber.make(from: "7.4"),
            PhpVersionNumber(major: 7, minor: 4, patch: nil)
        )
        XCTAssertEqual(
            PhpVersionNumber.make(from: "7"),
            nil
        )
    }
    
    func testCanCheckFixedConstraints() throws {
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
    
    func testCanCheckCaretConstraints() throws {
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
    
    func testCanCheckTildeConstraints() throws {
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
    
    func testCanCheckGreaterThanOrEqualConstraints() throws {
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
    
    func testCanCheckGreaterThanConstraints() throws {
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
}
