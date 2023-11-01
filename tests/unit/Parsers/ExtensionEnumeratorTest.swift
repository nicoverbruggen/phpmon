//
//  ExtensionEnumeratorTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 30/10/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

final class ExtensionEnumeratorTest: XCTestCase {

    override func setUp() async throws {
        ActiveFileSystem.useTestable([
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.1.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.2.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.3.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.4.rb": .fake(.text, "<test>"),
        ])
    }

    func testCanReadFormulae() throws {
        let directory = "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula"
        let files = try FileSystem.getShallowContentsOfDirectory(directory)

        XCTAssertEqual(
            Set(["xdebug@8.1.rb", "xdebug@8.2.rb", "xdebug@8.3.rb", "xdebug@8.4.rb"]),
            Set(files)
        )
    }

    func testCanParseFormulaeBasedOnSyntax() throws {
        let formulae = BrewTapFormulae.from(tap: "shivammathur/homebrew-extensions")

        XCTAssertEqual(formulae["8.1"], Set(["xdebug"]))
        XCTAssertEqual(formulae["8.2"], Set(["xdebug"]))
        XCTAssertEqual(formulae["8.3"], Set(["xdebug"]))
        XCTAssertEqual(formulae["8.4"], Set(["xdebug"]))
    }
    
}
