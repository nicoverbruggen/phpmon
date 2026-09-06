//
//  PhpVersionDetectionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/04/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation
import Combine

struct PhpVersionDetectionTest {
    @Test(arguments: [
        "not a version", "", "PHPMON_COMMAND_UNCAUGHT_SIGNAL", "PHPMON_FILE_HANDLE_READ_FAILURE",
        "999999999999999999999999.4.2"
    ])
    func malformed_installed_version_remains_available_for_repair(_ output: String) async throws {
        let container = Container.fake(
            shell: [
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant(""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.4/bin/php-config": .fake(.binary),
                "/opt/homebrew/opt/php@8.5/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.5/bin/php-config": .fake(.binary),
                "/usr/local/bin/": .fake(.directory, readOnly: true)
            ],
            commands: [
                "/opt/homebrew/opt/php@8.4/bin/php-config --version": output,
                "/opt/homebrew/opt/php@8.4/bin/php -v": "PHP 8.4.2",
                "/opt/homebrew/opt/php@8.5/bin/php-config --version": "8.5.1",
                "/opt/homebrew/opt/php@8.5/bin/php -v": "PHP 8.5.1"
            ]
        )
        let previousContainer = App.shared.container
        App.shared.container = container
        let previousInstalled = Valet.shared.installed
        let previousVersion = Valet.shared.version
        defer {
            App.shared.container = previousContainer
            Valet.shared.installed = previousInstalled
            Valet.shared.version = previousVersion
        }
        Valet.shared.installed = false
        Valet.shared.version = nil
        container.phpEnvs.homebrewPackage = Self.phpHomebrewPackage()

        let detected = await container.phpEnvs.detectPhpVersions()

        #expect(detected == ["8.4", "8.5"])
        #expect(container.phpEnvs.availablePhpVersions == ["8.5", "8.4"])
        let broken = try #require(container.phpEnvs.cachedPhpInstallations["8.4"])
        #expect(broken.versionNumber == VersionNumber(major: 8, minor: 4, patch: nil))
        #expect(!broken.isHealthy)
        #expect(!broken.isMissingBinary)
        let healthy = try #require(container.phpEnvs.cachedPhpInstallations["8.5"])
        #expect(healthy.versionNumber.long == "8.5.1")
        #expect(healthy.isHealthy)

        let formula = BrewPhpFormula(
            container, name: "php@8.4", displayName: "PHP 8.4",
            installedVersion: "8.4.2", upgradeVersion: nil
        )
        #expect(formula.isInstalled)
        #expect(!formula.healthy)
    }

    @Test(arguments: ["8.4.2", "8.4.2-dev"])
    func valid_installed_version_preserves_health_and_prerelease_status(_ output: String) async {
        let container = Container.fake(
            shell: [
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary),
                "/opt/homebrew/opt/php@8.4/bin/php-config": .fake(.binary)
            ],
            commands: [
                "/opt/homebrew/opt/php@8.4/bin/php-config --version": output,
                "/opt/homebrew/opt/php@8.4/bin/php -v": "PHP \(output)"
            ]
        )

        let installation = await PhpInstallation.detect(container, "8.4")

        #expect(installation.versionNumber == VersionNumber(major: 8, minor: 4, patch: 2))
        #expect(installation.isHealthy)
        #expect(!installation.isMissingBinary)
        #expect(installation.isPreRelease == output.contains("-dev"))
    }

    @Test func overlapping_detection_keeps_the_latest_versions_and_cache_consistent() async throws {
        let firstProbe = "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
        let container = Container.fake(
            shell: [
                firstProbe: .delayed(1, ""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary),
                "/usr/local/bin/": .fake(.directory, readOnly: true)
            ],
            commands: [
                "/opt/homebrew/opt/php@8.4/bin/php -v": "PHP 8.4.0",
                "/opt/homebrew/opt/php@8.5/bin/php -v": "PHP 8.5.0"
            ]
        )
        let previousContainer = App.shared.container
        App.shared.container = container
        let previousInstalled = Valet.shared.installed
        let previousVersion = Valet.shared.version
        defer {
            App.shared.container = previousContainer
            Valet.shared.installed = previousInstalled
            Valet.shared.version = previousVersion
        }
        Valet.shared.installed = false
        Valet.shared.version = nil
        container.phpEnvs.homebrewPackage = Self.phpHomebrewPackage()
        (container.shell as! TestableShell).allowsDelayedCommands = true

        let first = Task { await container.phpEnvs.detectPhpVersions() }
        for await commands in container.commandTracker.$commands.values
            where commands.contains(where: { $0.command == firstProbe }) {
            break
        }

        // A Homebrew change starts another scan while the first PHP probe is still running.
        try container.filesystem.remove("/opt/homebrew/opt/php@8.4")
        try container.filesystem.writeAtomicallyToFile("/opt/homebrew/opt/php@8.5/bin/php", content: "")
        await container.phpEnvs.detectPhpVersions()
        _ = await first.value

        #expect(container.phpEnvs.availablePhpVersions == ["8.5"])
        #expect(container.phpEnvs.cachedPhpInstallations.keys.sorted() == ["8.5"])
        let helper = try container.filesystem.getStringFromFile("/Users/fake/.config/phpmon/bin/pm85")
        #expect(helper.contains("PHP Monitor has enabled this terminal to use PHP 8.5."))
    }

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
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant(""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.4": .fake(.symlink, "/opt/homebrew/Cellar/php@8.4/8.4.0"),
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
                "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant(""),
                "/opt/homebrew/opt/php@8.5/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: [
                "/opt/homebrew/opt/php@8.5": .fake(.symlink, "/opt/homebrew/Cellar/php/8.5.0"),
                "/opt/homebrew/opt/php@8.4": .fake(.symlink, "/opt/homebrew/Cellar/php@8.4/8.4.0"),
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
