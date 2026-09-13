//
//  HomebrewCompatibilityTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import Testing

struct HomebrewCompatibilityTest {
    // Synthetic services info --json fixtures, with the same service states in both versions.
    // Schema: Homebrew's Library/Homebrew/services/formula_wrapper.rb, FormulaWrapper#to_hash.
    // Label migration: https://github.com/Homebrew/brew/pull/23750
    private func servicesJSON(version: Int, elevated: Bool) throws -> String {
        let domain = elevated ? "root" : "user"
        let url = try #require(TestBundle.url(forResource: "brew-\(version)-services-\(domain)", withExtension: "json"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test(arguments: [6, 7], [false, true])
    func queries_services_without_depending_on_launchd_labels(version: Int, elevated: Bool) async throws {
        let installed = ["php@8.4", "nginx", "dnsmasq", "postgresql@14", "postgresql@16", "redis"]
        let requested = elevated ? "'dnsmasq' 'nginx' 'php@8.4'" : "'postgresql@14' 'postgresql@16' 'redis'"
        let resolved = elevated ? "'dnsmasq' 'nginx' 'shivammathur/php/php@8.4'" : requested
        let command = "\(elevated ? "sudo " : "")/opt/homebrew/bin/brew services info \(resolved) --json"
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name \(requested)":
                .instant(resolved.replacing("'", with: "").replacing(" ", with: "\n")),
            command: .instant(try servicesJSON(version: version, elevated: elevated))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: elevated,
            formulae: [
                HomebrewFormula("php@8.4"), HomebrewFormula("nginx"), HomebrewFormula("dnsmasq"),
                HomebrewFormula("postgresql", elevated: false, servicePrefix: "postgresql@"),
                HomebrewFormula("redis", elevated: false)
            ],
            installedFormulae: installed
        )

        let prefix = version == 6 ? "homebrew.mxcl" : "sh.brew"
        #expect(services.map(\.name) == (elevated ? ["php@8.4", "nginx", "dnsmasq"] : ["postgresql@16", "redis"]))
        #expect(services.map(\.service_name) == services.map { "\(prefix).\($0.name)" })
        #expect(services.map(\.running) == (elevated ? [true, false, false] : [true, false]))
        #expect(services.map(\.loaded) == (elevated ? [true, true, true] : [true, false]))
        #expect(services.map(\.status) == (elevated ? ["started", "stopped", "error"] : ["started", "none"]))
        #expect(services.first?.user == (elevated ? "root" : "user"))
        if elevated {
            #expect(services.first?.log_path == "/opt/homebrew/var/log/php-fpm.log")
            #expect(services.first?.error_log_path == "/opt/homebrew/var/log/php-fpm.log")
        } else {
            #expect(services.last?.user == nil)
        }
    }

    @Test func refreshes_services_during_partial_label_migration() async throws {
        let legacyJSON = try servicesJSON(version: 6, elevated: true)
        let currentJSON = try servicesJSON(version: 7, elevated: true)
        let legacy = try #require(JSONSerialization.jsonObject(with: Data(legacyJSON.utf8)) as? [[String: Any]])
        let current = try #require(JSONSerialization.jsonObject(with: Data(currentJSON.utf8)) as? [[String: Any]])
        // PHP keeps its old registration while the other services have been restarted.
        let mixed = [try #require(legacy.first)] + current.dropFirst()
        let mixedJSON = try #require(String(data: JSONSerialization.data(withJSONObject: mixed), encoding: .utf8))
        let command = "sudo /opt/homebrew/bin/brew services info --all --json"
        let container = Container.fake(shell: [
            command: BatchFakeShellOutput(items: [.instant(legacyJSON)], transactions: [
                .shell(command, BatchFakeShellOutput(items: [.instant(mixedJSON)], transactions: [
                    .shell(command, .instant(currentJSON))
                ]))
            ])
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let expectedLabels = [
            ["homebrew.mxcl.php@8.4", "homebrew.mxcl.nginx", "homebrew.mxcl.dnsmasq"],
            ["homebrew.mxcl.php@8.4", "sh.brew.nginx", "sh.brew.dnsmasq"],
            ["sh.brew.php@8.4", "sh.brew.nginx", "sh.brew.dnsmasq"]
        ]

        for labels in expectedLabels {
            let services = await data.fetchHomebrewServices(
                elevated: true,
                formulae: [HomebrewFormula("php@8.4"), HomebrewFormula("nginx"), HomebrewFormula("dnsmasq")],
                installedFormulae: nil
            )
            #expect(services.map(\.service_name) == labels)
            #expect(services.map(\.name) == ["php@8.4", "nginx", "dnsmasq"])
            #expect(services.map(\.running) == [true, false, false])
        }
    }
}
