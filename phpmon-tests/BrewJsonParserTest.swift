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
        let json = try! String(contentsOf: Self.jsonBrewFile, encoding: .utf8)
        let package = try! JSONDecoder().decode(
            [HomebrewPackage].self, from: json.data(using: .utf8)!
        ).first!
        
        XCTAssertEqual(package.name, "php")
        XCTAssertEqual(package.full_name, "php")
        XCTAssertEqual(package.aliases.first!, "php@8.0")
        XCTAssertEqual(package.installed.contains(where: { installed in
            installed.version.starts(with: "8.0")
        }), true)
    }
    
    static var jsonBrewServicesFile: URL {
        return Bundle(for: Self.self).url(forResource: "brew-services", withExtension: "json")!
    }
    
    func testCanParseServicesJson() throws {
        let json = try! String(contentsOf: Self.jsonBrewServicesFile, encoding: .utf8)
        let services = try! JSONDecoder().decode(
            [HomebrewService].self, from: json.data(using: .utf8)!
        )
        
        XCTAssertGreaterThan(services.count, 0)
        XCTAssertEqual(services.first?.name, "dnsmasq")
        XCTAssertEqual(services.first?.service_name, "homebrew.mxcl.dnsmasq")
    }

}
