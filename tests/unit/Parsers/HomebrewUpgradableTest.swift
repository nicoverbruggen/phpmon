//
//  HomebrewTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class HomebrewUpgradableTest: XCTestCase {
    static var outdatedFileUrl: URL {
        return Bundle(for: Self.self)
            .url(forResource: "brew-outdated", withExtension: "json")!
    }

    func test_upgradable_php_versions_can_be_parsed() async throws {
        ActiveShell.useTestable([
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
        ])

        let env = PhpEnvironments.shared
        env.cachedPhpInstallations = [
            "8.1": PhpInstallation("8.1.16"),
            "8.2": PhpInstallation("8.2.3"),
            "7.4": PhpInstallation("7.4.11")
        ]

        let data = await BrewPhpFormulaeHandler().loadPhpVersions(loadOutdated: true)

        XCTAssertTrue(data.contains(where: { formula in
            formula.installedVersion == "8.1.16" && formula.upgradeVersion == "8.1.17"
        }))

        XCTAssertTrue(data.contains(where: { formula in
            formula.installedVersion == "8.2.3" && formula.upgradeVersion == "8.2.4"
        }))
    }
}
