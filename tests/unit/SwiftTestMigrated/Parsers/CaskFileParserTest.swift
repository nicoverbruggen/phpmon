//
//  CaskFileParserTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite(.serialized)
struct CaskFileParserTest {

    init() async throws {
        ActiveShell.useSystem()
    }

    // MARK: - Test Files
    static var exampleFilePath: URL {
        TestBundle.url(forResource: "phpmon-dev", withExtension: "rb")!
    }

    @Test func can_extract_fields_from_cask_file() async throws {
        guard let caskFile = await CaskFile.from(url: CaskFileParserTest.exampleFilePath) else {
            Issue.record("The CaskFile could not be parsed, check the log for more info")
            return
        }

        #expect(
            caskFile.version ==
            "5.7.2_1035"
        )
        #expect(
            caskFile.sha256 ==
            "1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a"
        )
        #expect(
            caskFile.name ==
            "PHP Monitor DEV"
        )
        #expect(
            caskFile.url ==
            "https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon-dev.zip"
        )
    }

    @Test func can_extract_fields_from_remote_cask_file() async throws {
        let url = URL(string: "https://raw.githubusercontent.com/nicoverbruggen/homebrew-cask/master/Casks/phpmon.rb")!

        guard let caskFile = await CaskFile.from(url: url) else {
            Issue.record("The remote CaskFile could not be parsed, check the log for more info")
            return
        }

        #expect(caskFile.properties.keys.contains("version"))
        #expect(caskFile.properties.keys.contains("homepage"))
        #expect(caskFile.properties.keys.contains("url"))
    }
}
