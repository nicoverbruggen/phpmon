//
//  ValetConfigParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class ValetConfigurationTest: XCTestCase {
    
    static var jsonConfigFileUrl: URL {
        return Bundle(for: Self.self).url(
            forResource: "valet-config",
            withExtension: "json"
        )!
    }
    
    func testCanLoadConfigFile() throws {
        let json = try? String(
            contentsOf: Self.jsonConfigFileUrl,
            encoding: .utf8
        )
        let config = try! JSONDecoder().decode(
            Valet.Configuration.self,
            from: json!.data(using: .utf8)!
        )
        
        XCTAssertEqual(config.tld, "test")
        XCTAssertEqual(config.paths, [
            "/Users/username/.config/valet/Sites",
            "/Users/username/Sites"
        ])
        XCTAssertEqual(config.defaultSite, "/Users/username/default-site")
        XCTAssertEqual(config.loopback, "127.0.0.1")
    }
    
}
