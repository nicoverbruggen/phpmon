//
//  CaskFileParserTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class CaskFileParserTest: XCTestCase {

    // MARK: - Test Files
    static var exampleFilePath: URL {
        return Bundle(for: Self.self)
            .url(forResource: "phpmon-dev", withExtension: "rb")!
    }

    func test_can_extract_fields_from_cask_file() async throws {
        guard let caskFile = await CaskFile.from(url: CaskFileParserTest.exampleFilePath) else {
            return XCTFail("The CaskFile could not be parsed, check the log for more info")
        }

        XCTAssertEqual(
            caskFile.version,
            "5.7.2_1035"
        )
        XCTAssertEqual(
            caskFile.sha256,
            "1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a"
        )
        XCTAssertEqual(
            caskFile.name,
            "PHP Monitor DEV"
        )
        XCTAssertEqual(
            caskFile.url,
            "https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon-dev.zip"
        )
    }

    func test_can_extract_fields_from_remote_cask_file() async throws {
        let url = URL(string: "https://raw.githubusercontent.com/nicoverbruggen/homebrew-cask/master/Casks/phpmon.rb")!

        guard let caskFile = await CaskFile.from(url: url) else {
            return XCTFail("The remote CaskFile could not be parsed, check the log for more info")
        }

        XCTAssertTrue(caskFile.properties.keys.contains("version"))
        XCTAssertTrue(caskFile.properties.keys.contains("homepage"))
        XCTAssertTrue(caskFile.properties.keys.contains("url"))
    }
}
