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

    static var path: URL {
        return Bundle(for: Self.self)
            .url(forResource: "valetrc", withExtension: "rc")!
    }

    // MARK: - Tests

    func test_can_extract_fields_from_valetrc_file() throws {
        // TODO: Load the path and get the fields
    }

    func test_skip_invalid_fields_valetrc_file() throws {
        // TODO: Load the path and throw error
    }

}
