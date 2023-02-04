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

    func test_can_extract_fields_from_cask_file() throws {
        let caskFile = CaskFile.from(url: CaskFileParserTest.exampleFilePath)

        XCTAssertEqual(
            caskFile!.properties["version"],
            "5.7.2_1035"
        )
        XCTAssertEqual(
            caskFile!.properties["homepage"],
            "https://phpmon.app"
        )
        XCTAssertEqual(
            caskFile!.properties["appcast"],
            "https://github.com/nicoverbruggen/phpmon/releases.atom"
        )
        XCTAssertEqual(
            caskFile!.properties["url"],
            "https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon-dev.zip"
        )
    }

    func test_can_extract_fields_from_remote_cask_file() throws {
        let caskFile = CaskFile.from(url: Constants.Urls.StableBuildCaskFile)

        XCTAssertTrue(caskFile!.properties.keys.contains("version"))
        XCTAssertTrue(caskFile!.properties.keys.contains("homepage"))
        XCTAssertTrue(caskFile!.properties.keys.contains("url"))
        XCTAssertTrue(caskFile!.properties.keys.contains("appcast"))
    }
}
