//
//  ExtensionParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class ExtensionParserTest: XCTestCase {
    
    static var phpIniFileUrl: URL {
        return Bundle(for: Self.self).url(forResource: "php", withExtension: "ini")!
    }

    func testCanLoadExtension() throws {
        let extensions = PhpExtension.load(from: Self.phpIniFileUrl)
        
        XCTAssertGreaterThan(extensions.count, 0)
    }
    
    func testExtensionNameIsCorrect() throws {
        let extensions = PhpExtension.load(from: Self.phpIniFileUrl)
        
        XCTAssertEqual(extensions.first!.name, "xdebug")
        XCTAssertEqual(extensions.last!.name, "imagick")
    }
    
    func testExtensionStatusIsCorrect() throws {
        let extensions = PhpExtension.load(from: Self.phpIniFileUrl)
        
        XCTAssertEqual(extensions.first!.enabled, true)
        XCTAssertEqual(extensions.last!.enabled, false)
    }
    
    func testToggleWorksAsExpected() throws {
        let destination = Utility.copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!
        let extensions = PhpExtension.load(from: destination)
        XCTAssertEqual(extensions.count, 2)
        
        // Try to disable it!
        let xdebug = extensions.first!
        XCTAssertEqual(xdebug.enabled, true)
        xdebug.toggle()
        XCTAssertEqual(xdebug.enabled, false)
        
        // Check if the file contains the appropriate data
        let file = try! String(contentsOf: destination, encoding: .utf8)
        XCTAssertTrue(file.contains("; zend_extension=\"xdebug.so\""))
        
        // Make sure if we load the data again, it's disabled
        XCTAssertEqual(PhpExtension.load(from: destination).first!.enabled, false)
    }

}
