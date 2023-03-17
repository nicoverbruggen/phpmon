//
//  HomebrewTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class HomebrewTest: XCTestCase {
    static var outdatedFileUrl: URL {
        return Bundle(for: Self.self)
            .url(forResource: "brew-outdated", withExtension: "json")!
    }

    func test_upgradable_php_versions_can_be_parsed() async throws {
        ActiveShell.useTestable([
            "/opt/homebrew/bin/brew update >/dev/null && /opt/homebrew/bin/brew outdated --json --formulae": .instant(try! String(contentsOf: Self.outdatedFileUrl))
        ])

        let env = PhpEnv.shared
        env.cachedPhpInstallations = [
            "8.1": PhpInstallation("8.1.3"),
            "8.2": PhpInstallation("8.2.4"),
            "7.4": PhpInstallation("7.4.11")
        ]

        let brew = Brew.shared
        let data = await brew.getPhpVersions()
        print(data)
    }
}
