//
//  BrewJsonParserTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 14/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class HomebrewPackageTest: XCTestCase {
    
    // - MARK: SYNTHETIC TESTS

    static var jsonBrewFile: URL {
        return Bundle(for: Self.self)
            .url(forResource: "brew-formula", withExtension: "json")!
    }

    func testCanLoadExtensionJson() throws {
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
        return Bundle(for: Self.self)
            .url(forResource: "brew-services", withExtension: "json")!
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
    
    // - MARK: LIVE TESTS

    /// This test requires that you have a valid Homebrew installation set up,
    /// and requires the Valet services to be installed: php, nginx and dnsmasq.
    /// If this test fails, there is an issue with your Homebrew installation
    /// or the JSON API of the Homebrew output may have changed.
    func testCanParseServicesJsonFromCliOutput() throws {
        let services = try! JSONDecoder().decode(
            [HomebrewService].self,
            from: Shell.pipe(
                "sudo \(Paths.brew) services info --all --json",
                requiresPath: true
            ).data(using: .utf8)!
        ).filter({ service in
            return ["php", "nginx", "dnsmasq"].contains(service.name)
        })
        
        XCTAssertTrue(services.contains(where: {$0.name == "php"} ))
        XCTAssertTrue(services.contains(where: {$0.name == "nginx"} ))
        XCTAssertTrue(services.contains(where: {$0.name == "dnsmasq"} ))
        XCTAssertEqual(services.count, 3)
    }
    
    /// This test requires that you have a valid Homebrew installation set up,
    /// and requires the `php` formula to be installed.
    /// If this test fails, there is an issue with your Homebrew installation
    /// or the JSON API of the Homebrew output may have changed.
    func testCanLoadExtensionJsonFromCliOutput() throws {
        let package = try! JSONDecoder().decode(
            [HomebrewPackage].self,
            from: Shell.pipe("\(Paths.brew) info php --json", requiresPath: true).data(using: .utf8)!
        ).first!
        
        XCTAssertTrue(package.name == "php")
    }
}
