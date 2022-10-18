//
//  ExtensionParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class PhpExtensionTest: XCTestCase {

    static var phpIniFileUrl: URL {
        return Bundle(for: Self.self).url(forResource: "php", withExtension: "ini")!
    }

    func test_can_load_extension() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        XCTAssertGreaterThan(extensions.count, 0)
    }

    func test_extension_name_is_correct() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        let extensionNames = extensions.map { (ext) -> String in
            return ext.name
        }

        // These 6 should be found
        XCTAssertTrue(extensionNames.contains("xdebug"))
        XCTAssertTrue(extensionNames.contains("imagick"))
        XCTAssertTrue(extensionNames.contains("sodium-next"))
        XCTAssertTrue(extensionNames.contains("opcache"))
        XCTAssertTrue(extensionNames.contains("yaml"))
        XCTAssertTrue(extensionNames.contains("custom"))

        XCTAssertFalse(extensionNames.contains("fake"))
        XCTAssertFalse(extensionNames.contains("nice"))
    }

    func test_extension_status_is_correct() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        // xdebug should be enabled
        XCTAssertEqual(extensions[0].enabled, true)

        // imagick should be disabled
        XCTAssertEqual(extensions[1].enabled, false)
    }

    func test_toggle_works_as_expected() async throws {
        let destination = Utility.copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!
        let extensions = PhpExtension.from(filePath: destination.path)
        XCTAssertEqual(extensions.count, 6)

        // Try to disable xdebug (should be detected first)!
        let xdebug = extensions.first!
        XCTAssertTrue(xdebug.name == "xdebug")
        XCTAssertEqual(xdebug.enabled, true)
        await xdebug.toggle()
        XCTAssertEqual(xdebug.enabled, false)

        // Check if the file contains the appropriate data
        let file = try! String(contentsOf: destination, encoding: .utf8)
        XCTAssertTrue(file.contains("; zend_extension=\"xdebug.so\""))

        // Make sure if we load the data again, it's disabled
        XCTAssertEqual(PhpExtension.from(filePath: destination.path).first!.enabled, false)
    }

}
