//
//  PhpEnvironmentIsolationTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct PhpEnvironmentIsolationTest {
    @Test func missing_homebrew_metadata_does_not_crash_alias_detection() async {
        let container = Container.fake()
        await container.phpEnvs.determinePhpAlias()
        #expect(container.phpEnvs.brewPhpAlias == nil)
    }

    @Test func refreshing_one_environment_does_not_change_another() async {
        let first = Container.fake()
        let second = Container.fake()
        first.phpEnvs.homebrewPackage = package(version: "8.3.0")
        second.phpEnvs.homebrewPackage = package(version: "8.4.0")
        let firstHandler = BrewPhpFormulaeHandler(first)
        let secondHandler = BrewPhpFormulaeHandler(second)

        async let firstRefresh: Void = firstHandler.refreshPhpVersions(loadOutdated: false)
        async let secondRefresh: Void = secondHandler.refreshPhpVersions(loadOutdated: false)
        _ = await (firstRefresh, secondRefresh)

        #expect(first.phpEnvs.brewPhpAlias == "8.3")
        #expect(second.phpEnvs.brewPhpAlias == "8.4")
        #expect(!firstHandler.formulae.phpVersions.isEmpty)
        #expect(!secondHandler.formulae.phpVersions.isEmpty)
        #expect(firstHandler.formulae.phpVersions.allSatisfy { $0.container === first })
        #expect(secondHandler.formulae.phpVersions.allSatisfy { $0.container === second })
    }

    private func package(version: String) -> HomebrewPackage {
        HomebrewPackage(
            full_name: "php", aliases: [], installed: [],
            versions: HomebrewVersion(stable: version, head: nil, bottle: true), linked_keg: nil
        )
    }
}
