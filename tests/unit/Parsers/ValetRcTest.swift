//
//  ValetRcTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 20/01/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class ValetRcTest: XCTestCase {

    // MARK: - Test Files

    static var validPath: URL {
        return Bundle(for: Self.self)
            .url(forResource: "valetrc", withExtension: "valid")!
    }

    static var brokenPath: URL {
        return Bundle(for: Self.self)
            .url(forResource: "valetrc", withExtension: "broken")!
    }


    // MARK: - Tests

    func test_can_extract_fields_from_valetrc_file() throws {
        let fakeFile = RCFile.fromPath("/Users/fake/file.rc")
        XCTAssertNil(fakeFile)

        // Can parse the file
        let validFile = RCFile.fromPath(ValetRcTest.validPath.path)
        XCTAssertNotNil(validFile)

        let fields = validFile!.fields

        // Correctly parses and trims (and omits double quotes) per line
        XCTAssertEqual(fields["PHP"], "php@8.2")
        XCTAssertEqual(fields["OTHER"], "thing")
        XCTAssertEqual(fields["PHPMON_WATCH"], "true")
        XCTAssertEqual(fields["SYNTAX"], "variable")

        // Ignores entries prefixed with #
        XCTAssertTrue(!fields.keys.contains("#PHP"))

        // Ignores invalid lines
        XCTAssertTrue(!fields.keys.contains("OOF"))
    }
}
