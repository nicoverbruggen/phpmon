//
//  HomebrewTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct HomebrewUpgradableTest {
    var container: Container
    init() throws {
        container = Container.fake(
            shell: [
                "/opt/homebrew/bin/brew update >/dev/null && /opt/homebrew/bin/brew outdated --json --formulae"
                : .instant(try! String(contentsOf: Self.outdatedFileUrl)),
                "/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
                : .instant("/opt/homebrew/etc/php/8.2/conf.d/php-memory-limits.ini"),
                "/opt/homebrew/opt/php@8.1.16/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
                : .instant("/opt/homebrew/etc/php/8.1/conf.d/php-memory-limits.ini"),
                "/opt/homebrew/opt/php@8.2.3/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
                : .instant("/opt/homebrew/etc/php/8.2/conf.d/php-memory-limits.ini"),
                "/opt/homebrew/opt/php@7.4.11/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
                : .instant("/opt/homebrew/etc/php/7.4/conf.d/php-memory-limits.ini")
            ],
            files: [
                "/opt/homebrew/etc/php/8.2/conf.d/php-memory-limits.ini": .fake(.text),
                "/opt/homebrew/etc/php/8.1/conf.d/php-memory-limits.ini": .fake(.text),
                "/opt/homebrew/etc/php/7.4/conf.d/php-memory-limits.ini": .fake(.text)
            ]
        )
    }

    static var outdatedFileUrl: URL {
        return TestBundle.url(forResource: "brew-outdated", withExtension: "json")!
    }

    @Test func upgradable_php_versions_can_be_determined() async throws {
        // This config file assumes our PHP alias (`php`) is v8.2
        PhpEnvironments.brewPhpAlias = "8.2"
        let env = container.phpEnvs!
        env.cachedPhpInstallations = [
            "8.1": PhpInstallation(container, "8.1.16"),
            "8.2": PhpInstallation(container, "8.2.3"),
            "7.4": PhpInstallation(container, "7.4.11")
        ]

        let data = await BrewPhpFormulaeHandler(container)
            .loadPhpVersions(loadOutdated: true)

        #expect(true == data.contains(where: { formula in
            formula.installedVersion == "8.1.16" && formula.upgradeVersion == "8.1.17"
        }))

        #expect(true == data.contains(where: { formula in
            formula.installedVersion == "8.2.3" && formula.upgradeVersion == "8.2.4"
        }))
    }
}
