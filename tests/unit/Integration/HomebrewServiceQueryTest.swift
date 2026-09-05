//
//  HomebrewServiceQueryTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import Testing

@Suite(.serialized)
struct HomebrewServiceQueryTest {
    init() {
        App.shared.container = Container.fake()
    }

    private func response(_ names: [String], running: Bool = true) throws -> String {
        let services = names.map {
            ["name": $0, "service_name": "homebrew.mxcl.\($0)", "running": running, "loaded": running] as [String: Any]
        }
        return try #require(String(data: JSONSerialization.data(withJSONObject: services), encoding: .utf8))
    }

    @Test func queries_only_installed_services_in_the_requested_domain() async throws {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'nginx-full' 'php@8.4'":
                .instant("custom/nginx/nginx-full\nshivammathur/php/php@8.4"),
            "sudo /opt/homebrew/bin/brew services info 'custom/nginx/nginx-full' 'shivammathur/php/php@8.4' --json":
                .instant(try response(["nginx-full", "php@8.4"]))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true,
            formulae: [HomebrewFormula("php@8.4"), HomebrewFormula("nginx-full"),
                       HomebrewFormula("dnsmasq"), HomebrewFormula("redis", elevated: false)],
            installedFormulae: ["php", "php@8.4", "nginx-full", "redis", "php@8.4"]
        )

        #expect(services.map(\.name) == ["php@8.4", "nginx-full"])
    }

    @Test func preserves_latest_versioned_service_selection() async throws {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'postgresql' 'postgresql@14' 'postgresql@16'":
                .instant("postgresql\npostgresql@14\npostgresql@16"),
            "/opt/homebrew/bin/brew services info 'postgresql' 'postgresql@14' 'postgresql@16' --json":
                .instant(try response(["postgresql@14", "postgresql", "postgresql@16"]))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: false,
            formulae: [HomebrewFormula("postgresql", elevated: false, servicePrefix: "postgresql@")],
            installedFormulae: ["postgresql", "postgresql@14", "postgresql@16", "postgresql-helper"]
        )

        #expect(services.map(\.name) == ["postgresql@16"])
    }

    @Test func custom_service_keeps_its_exact_name() async throws {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'redis@7.2'": .instant("redis@7.2"),
            "/opt/homebrew/bin/brew services info 'redis@7.2' --json": .instant(try response(["redis@7.2"]))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: false,
            formulae: [HomebrewFormula("redis@7.2", elevated: false)],
            installedFormulae: ["redis", "redis@7.2", "redis@8.0"]
        )

        #expect(services.map(\.name) == ["redis@7.2"])
    }

    @Test func skips_empty_domains_and_uninstalled_services() async {
        // No shell responses: any subprocess call fails this test.
        let container = Container.fake()
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let formulae = [HomebrewFormula("php")]
        let user = await data.fetchHomebrewServices(elevated: false, formulae: formulae, installedFormulae: nil)
        let root = await data.fetchHomebrewServices(elevated: true, formulae: formulae, installedFormulae: ["redis"])

        #expect(user.isEmpty)
        #expect(root.isEmpty)
    }

    @Test(arguments: [false, true])
    func falls_back_when_named_query_fails(partialJSON: Bool) async throws {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'php'": .instant("php"),
            "sudo /opt/homebrew/bin/brew services info 'php' --json": .with([
                .instant(partialJSON ? try response(["php"]) : "invalid JSON"),
                .instant("Formula disappeared during query", .stdErr)
            ]),
            "sudo /opt/homebrew/bin/brew services info --all --json": .instant(try response(["php"], running: false))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true, formulae: [HomebrewFormula("php")], installedFormulae: ["php"]
        )

        #expect(services.count == 1)
        #expect(services.first?.running == false)
    }

    @Test func uses_all_when_installed_formula_discovery_is_unavailable() async throws {
        let container = Container.fake(shell: [
            "sudo /opt/homebrew/bin/brew services info --all --json": .instant(try response(["php", "redis"]))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true, formulae: [HomebrewFormula("php")], installedFormulae: nil
        )

        #expect(services.map(\.name) == ["php"])
    }

    @Test(arguments: ["", "other", "--option/tap/php", "tap/repo/php\nextra"])
    func falls_back_when_full_names_cannot_be_resolved(output: String) async throws {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'php'": .instant(output),
            "sudo /opt/homebrew/bin/brew services info --all --json": .instant(try response(["php"]))
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true, formulae: [HomebrewFormula("php")], installedFormulae: ["php"]
        )

        #expect(services.map(\.name) == ["php"])
    }

    @Test func reload_refreshes_installed_formulae() async throws {
        let list = "/opt/homebrew/bin/brew list --formula"
        let container = Container.fake(shell: [
            list: BatchFakeShellOutput(items: [.instant("php")], transactions: [
                .shell(list, .instant("nginx"))
            ]),
            "/opt/homebrew/bin/brew list --formula --full-name 'php'": .instant("php"),
            "/opt/homebrew/bin/brew list --formula --full-name 'nginx'": .instant("nginx"),
            "sudo /opt/homebrew/bin/brew services info 'php' --json": .instant(try response(["php"])),
            "sudo /opt/homebrew/bin/brew services info 'nginx' --json": .instant(try response(["nginx"]))
        ])
        let wasInstalled = Valet.shared.installed
        Valet.shared.installed = true
        defer { Valet.shared.installed = wasInstalled }
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))

        let first = await data.reloadServicesStatus(isRetry: true)
        let second = await data.reloadServicesStatus(isRetry: true)

        #expect(first.map(\.name) == ["php"])
        #expect(second.map(\.name) == ["nginx"])
    }

    @Test func expired_reload_does_not_start_more_queries() async {
        let container = Container.fake()
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true, formulae: [HomebrewFormula("php")], installedFormulae: ["php"], deadline: 0
        )

        #expect(services.isEmpty)
    }

    @Test func failed_fallback_returns_unknown_state() async {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew list --formula --full-name 'php'": .instant("php"),
            "sudo /opt/homebrew/bin/brew services info 'php' --json": .instant("invalid JSON"),
            "sudo /opt/homebrew/bin/brew services info --all --json": .instant("invalid JSON")
        ])
        let data = ValetServicesDataManager(container, registry: ServicesRegistry(container))
        let services = await data.fetchHomebrewServices(
            elevated: true, formulae: [HomebrewFormula("php")], installedFormulae: ["php"]
        )

        #expect(services.isEmpty)
    }
}
