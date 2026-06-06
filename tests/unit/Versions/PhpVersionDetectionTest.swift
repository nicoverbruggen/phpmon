//
//  PhpVersionDetectionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct PhpVersionDetectionTest {
    private static func phpHomebrewPackage(version: String = "8.5.0") -> HomebrewPackage {
        return HomebrewPackage(
            full_name: "php",
            aliases: [],
            installed: [],
            versions: HomebrewVersion(stable: version, head: nil, bottle: true),
            linked_keg: nil
        )
    }

    @Test func test_can_detect_valid_php_versions() async throws {
        let container = Container.real()

        let versions = await container.phpEnvs.extractPhpVersions(
            from: [
                "", // empty lines should be omitted
                "php@8.0",
                "php@8.0", // should only be detected once
                "meta-php@8.0", // should be omitted, invalid
                "php@8.0-coolio", // should be omitted, invalid
                "php@7.0",
                "",
                "unrelatedphp@1.0", // should be omitted, invalid
                "php@5.6", // should be omitted, not supported
                "php@5.4" // should be omitted, not supported
            ],
            checkBinaries: false
        )

        #expect(versions == ["8.0", "7.0", "5.6"])
    }

    @Test func detect_php_versions_generates_helpers_and_includes_php_alias() async throws {
        let container = Container.fake(
            shell: [
                "ls /opt/homebrew/opt | grep php@": .instant("php@8.4\n"),
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant(""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.5/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.5/bin/php-config": .fake(.binary),
                "/opt/homebrew/opt/php/bin/php": .fake(.binary),
                "/usr/local/bin/": .fake(.directory, readOnly: true)
            ],
            commands: [
                "/opt/homebrew/opt/php@8.4/bin/php -v": "PHP 8.4.0",
                "/opt/homebrew/opt/php@8.5/bin/php -v": "PHP 8.5.0",
                "/opt/homebrew/opt/php@8.5/bin/php-config --version": "8.5.0"
            ]
        )

        container.phpEnvs.homebrewPackage = Self.phpHomebrewPackage()

        defer {
            Valet.shared.installed = false
            Valet.shared.version = nil
        }

        Valet.shared.installed = false
        Valet.shared.version = nil

        let detected = await container.phpEnvs.detectPhpVersions()

        #expect(detected == ["8.4", "8.5"])
        #expect(container.phpEnvs.availablePhpVersions == ["8.5", "8.4"])
        #expect(container.phpEnvs.incompatiblePhpVersions.isEmpty)
        #expect(container.phpEnvs.cachedPhpInstallations.keys.sorted() == ["8.4", "8.5"])
        #expect(container.filesystem.fileExists("/Users/fake/.config/phpmon/bin/pm84"))
        #expect(container.filesystem.fileExists("/Users/fake/.config/phpmon/bin/pm85"))

        let aliasHelper = try container.filesystem.getStringFromFile("/Users/fake/.config/phpmon/bin/pm85")
        let missingHelper = try container.filesystem.getStringFromFile("/Users/fake/.config/phpmon/bin/pm83")

        #expect(aliasHelper.contains("PHP Monitor has enabled this terminal to use PHP 8.5."))
        #expect(missingHelper.contains("Error: PHP 8.3 is not installed."))
    }

    @Test func detect_php_versions_tracks_valet_incompatible_versions_separately() async throws {
        let container = Container.fake(
            shell: [
                "ls /opt/homebrew/opt | grep php@": .instant("php@8.4\nphp@8.5\n"),
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant(""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.5/bin/php": .fake(.binary),
                "/usr/local/bin/": .fake(.directory, readOnly: true)
            ],
            commands: [
                "/opt/homebrew/opt/php@8.4/bin/php -v": "PHP 8.4.0",
                "/opt/homebrew/opt/php@8.5/bin/php -v": "PHP 8.5.0"
            ]
        )

        container.phpEnvs.homebrewPackage = Self.phpHomebrewPackage()

        defer {
            Valet.shared.installed = false
            Valet.shared.version = nil
        }

        Valet.shared.installed = true
        Valet.shared.version = VersionNumber(major: 3, minor: 0, patch: 0)

        let detected = await container.phpEnvs.detectPhpVersions()

        #expect(detected == ["8.4"])
        #expect(container.phpEnvs.availablePhpVersions == ["8.4"])
        #expect(container.phpEnvs.incompatiblePhpVersions == ["8.5"])

        let supportedHelper = try container.filesystem.getStringFromFile("/Users/fake/.config/phpmon/bin/pm84")
        let unsupportedInstalledHelper = try container.filesystem.getStringFromFile("/Users/fake/.config/phpmon/bin/pm85")

        #expect(supportedHelper.contains("PHP Monitor has enabled this terminal to use PHP 8.4."))
        #expect(unsupportedInstalledHelper.contains("PHP Monitor has enabled this terminal to use PHP 8.5."))
    }
}
