//
//  NginxParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class NginxParserTest: XCTestCase {
    
    static var regularUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nicoverbruggen", withExtension: "test")!
    }
    
    static var isolatedUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nicoverbruggen_isolated", withExtension: "test")!
    }
    
    func testCanDetermineIsolation() throws {
        XCTAssertNil(ValetSite.isolatedVersion(NginxParserTest.regularUrl.path))
        XCTAssertEqual("8.1", ValetSite.isolatedVersion(NginxParserTest.isolatedUrl.path))
    }
    
}
