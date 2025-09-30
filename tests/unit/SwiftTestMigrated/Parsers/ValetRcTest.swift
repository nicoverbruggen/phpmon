//
//  ValetRcTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 20/01/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct ValetRcTest {
    // MARK: - Test Files
    static var validPath: URL {
        TestBundle.url(forResource: "valetrc", withExtension: "valid")!
    }

    static var brokenPath: URL {
        TestBundle.url(forResource: "valetrc", withExtension: "broken")!
    }

    // MARK: - Tests
    @Test func can_extract_fields_from_valet_rc_file() throws {
        let fakeFile = RCFile.fromPath("/Users/fake/file.rc")
        #expect(nil == fakeFile)

        // Can parse the file
        let validFile = RCFile.fromPath(ValetRcTest.validPath.path)
        #expect(nil != validFile)

        let fields = validFile!.fields

        // Correctly parses and trims (and omits double quotes) per line
        #expect(fields["PHP"] == "php@8.2")
        #expect(fields["OTHER"] == "thing")
        #expect(fields["PHPMON_WATCH"] == "true")
        #expect(fields["SYNTAX"] == "variable")

        // Ignores entries prefixed with #
        #expect(!fields.keys.contains("#PHP"))

        // Ignores invalid lines
        #expect(!fields.keys.contains("OOF"))
    }
}
