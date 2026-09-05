//
//  ActivePhpInstallationTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("Active PHP Installation Detection")
struct ActivePhpInstallationTest {

    @Test(arguments: ["not a version", "PHPMON_COMMAND_UNCAUGHT_SIGNAL", "PHPMON_FILE_HANDLE_READ_FAILURE"])
    func unparseable_version_output_marks_the_installation_broken(_ output: String) async throws {
        let container = Container.fake(
            shell: [
                "/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
            ],
            files: ["/opt/homebrew/bin/php-config": .fake(.binary)],
            commands: [
                "/opt/homebrew/bin/php-config --version": output,
                "/opt/homebrew/bin/php -r echo ini_get('memory_limit');": "128M",
                "/opt/homebrew/bin/php -r echo ini_get('upload_max_filesize');": "2M",
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "8M"
            ]
        )

        let install = try #require(await ActivePhpInstallation.load(container))
        #expect(install.hasErrorState)
        #expect(install.limits.memory_limit == "???")
    }

    @Test func load_returns_nil_when_php_config_is_missing() async {
        // A container without a php-config binary means no linked installation.
        let container = Container.fake()

        let install = await ActivePhpInstallation.load(container)

        #expect(install == nil)
    }

    @Test func load_detects_version_limits_and_ini_files() async throws {
        let container = Container.fake(
            shell: [
                "/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'":
                    .instant("/opt/homebrew/etc/php/8.4/php.ini")
            ],
            files: [
                "/opt/homebrew/bin/php-config": .fake(.binary),
                "/opt/homebrew/etc/php/8.4/php.ini": .fake(.text, "memory_limit = 512M")
            ],
            commands: [
                "/opt/homebrew/bin/php-config --version": "8.4.2",
                "/opt/homebrew/bin/php -r echo ini_get('memory_limit');": "512M",
                "/opt/homebrew/bin/php -r echo ini_get('upload_max_filesize');": "64M",
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "-1"
            ]
        )

        let install = try #require(await ActivePhpInstallation.load(container))

        #expect(install.hasErrorState == false)
        #expect(install.version.long == "8.4.2")
        #expect(install.limits.memory_limit == "512MB")
        #expect(install.limits.upload_max_filesize == "64MB")
        #expect(install.limits.post_max_size == "∞")
        #expect(install.iniFiles.count == 1)
        #expect(install.iniFiles.first?.filePath == "/opt/homebrew/etc/php/8.4/php.ini")
    }

    @Test func broken_version_output_results_in_error_state_and_skips_probes() async throws {
        // When `php-config --version` reports a warning, the installation is
        // considered broken: no limits are probed and no .ini files are read.
        let container = Container.fake(
            files: [
                "/opt/homebrew/bin/php-config": .fake(.binary)
            ],
            commands: [
                "/opt/homebrew/bin/php-config --version": "Warning: something is misconfigured"
            ]
        )

        let install = try #require(await ActivePhpInstallation.load(container))

        #expect(install.hasErrorState == true)
        #expect(install.limits.memory_limit == "???")
        #expect(install.iniFiles.isEmpty)
    }
}
