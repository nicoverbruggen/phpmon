//
//  BrewJsonParserTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/02/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct HomebrewPackageTest {

    // - MARK: SYNTHETIC TESTS

    static var jsonBrewFile: URL {
        TestBundle.url(forResource: "brew-formula", withExtension: "json")!
    }

    static var jsonBrewServicesFile: URL {
        TestBundle.url(forResource: "brew-services", withExtension: "json")!
    }

    @Test func can_load_extension_json() throws {
        let json = try! String(contentsOf: Self.jsonBrewFile, encoding: .utf8)
        let package = try! JSONDecoder().decode(
            [HomebrewPackage].self, from: json.data(using: .utf8)!
        ).first!

        #expect(package.full_name == "php")
        #expect(package.aliases.first! == "php@8.4")
        #expect(package.installed.contains(where: { installed in
            installed.version.starts(with: "8.4")
        }) == true)
    }

    @Test func can_parse_services_json() throws {
        let json = try! String(contentsOf: Self.jsonBrewServicesFile, encoding: .utf8)
        let services = try! JSONDecoder().decode(
            [HomebrewService].self, from: json.data(using: .utf8)!
        )

        #expect(!services.isEmpty)
        #expect(services.first?.name == "dnsmasq")
        #expect(services.first?.service_name == "homebrew.mxcl.dnsmasq")
    }

    // - MARK: LIVE TESTS

    /// This test requires that you have a valid Homebrew installation set up,
    /// and requires the Valet services to be installed: php, nginx and dnsmasq.
    /// If this test fails, there is an issue with your Homebrew installation
    /// or the JSON API of the Homebrew output may have changed.
    @Test(.disabled("Uses system command; enable at your own risk"))
    func can_parse_services_json_from_cli_output() async throws {
        let container = Container.real(minimal: true)

        let services = try! JSONDecoder().decode(
            [HomebrewService].self,
            from: await container.shell.pipe(
                "sudo \(container.paths.brew) services info --all --json"
            ).out.data(using: .utf8)!
        ).filter({ service in
            return ["php", "nginx", "dnsmasq"].contains(service.name)
        })

        #expect(services.contains(where: {$0.name == "php"}))
        #expect(services.contains(where: {$0.name == "nginx"}))
        #expect(services.contains(where: {$0.name == "dnsmasq"}))
        #expect(services.count == 3)
    }

    /// This test requires that you have a valid Homebrew installation set up,
    /// and requires the `php` formula to be installed.
    /// If this test fails, there is an issue with your Homebrew installation
    /// or the JSON API of the Homebrew output may have changed.
    @Test(.disabled("Uses system command; enable at your own risk"))
    func can_load_extension_json_from_cli_output() async throws {
        let container = Container.real(minimal: true)

        let package = try! JSONDecoder().decode(
            [HomebrewPackage].self,
            from: await container.shell.pipe("\(container.paths.brew) info php --json").out.data(using: .utf8)!
        ).first!

        #expect(package.full_name == "php")
    }
}
