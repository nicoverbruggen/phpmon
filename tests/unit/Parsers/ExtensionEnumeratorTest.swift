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
        let directory = "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula"
        let files = try FileSystem.getShallowContentsOfDirectory(directory)

        // TODO: Put this in a separate class
        var versionExtensionsMap = [String: Set<String>]()
        let regex = try! NSRegularExpression(pattern: "(\\w+)@(\\d+\\.\\d+)\\.rb")
        for file in files {
            let matches = regex.matches(in: file, range: NSRange(file.startIndex..., in: file))
            if let match = matches.first {
                if let phpExtensionRange = Range(match.range(at: 1), in: file),
                   let versionRange = Range(match.range(at: 2), in: file) {
                    let phpExtension = String(file[phpExtensionRange])
                    let version = String(file[versionRange])

                    if var extensions = versionExtensionsMap[version] {
                        extensions.insert(phpExtension)
                        versionExtensionsMap[version] = extensions
                    } else {
                        versionExtensionsMap[version] = [phpExtension]
                    }
                }
            }
        }

        XCTAssertEqual(versionExtensionsMap["8.1"], Set(["xdebug"]))
        XCTAssertEqual(versionExtensionsMap["8.2"], Set(["xdebug"]))
        XCTAssertEqual(versionExtensionsMap["8.3"], Set(["xdebug"]))
        XCTAssertEqual(versionExtensionsMap["8.4"], Set(["xdebug"]))
    }
}
