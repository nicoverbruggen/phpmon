//
//  BrewJsonParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 14/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class BrewJsonParserTest: XCTestCase {

    static var jsonBrewFile: URL {
        return Bundle(for: Self.self).url(forResource: "brew", withExtension: "json")!
    }

    func testCanLoadExtension() throws {
        let json = try? String(contentsOf: Self.jsonBrewFile, encoding: .utf8)
        let package = try! JSONDecoder().decode(
            [HomebrewPackage].self, from: json!.data(using: .utf8)!
        ).first!
        
        XCTAssertEqual(package.name, "php")
        XCTAssertEqual(package.full_name, "php")
        XCTAssertEqual(package.aliases.first!, "php@8.0")
    }

}
