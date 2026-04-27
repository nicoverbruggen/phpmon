//
//  PhpHelperTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct PhpHelperTest {
    @Test func installed_helper_contains_php_path() async throws {
        let container = Container.fake(files: [
            "/usr/local/bin/": .fake(.directory, readOnly: true),
            "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary)
        ])

        let writtenFiles = await PhpHelper.regenerate(container, installedVersions: ["8.4"])
        let helperPath = "/Users/fake/.config/phpmon/bin/pm84"
        let contents = try container.filesystem.getStringFromFile(helperPath)

        #expect(writtenFiles.count == Constants.DetectedPhpVersions.count)
        #expect(writtenFiles.contains(helperPath))
        #expect(contents.contains("PHP Monitor has enabled this terminal to use PHP 8.4."))
        #expect(contents.contains("export PATH=/opt/homebrew/Cellar/php@8.4"))
        #expect(container.filesystem.isExecutableFile(helperPath))
    }

    @Test func missing_helper_shows_not_installed_notice() async throws {
        let container = Container.fake(files: [
            "/usr/local/bin/": .fake(.directory, readOnly: true)
        ])

        let writtenFiles = await PhpHelper.regenerate(container, installedVersions: [])

        // Check various PHP versions (this may need to be updated periodically)
        let items = [
            "pm56",
            "pm70", "pm71", "pm72", "pm73", "pm74",
            "pm80", "pm81", "pm82", "pm83", "pm84", "pm85", "pm86"
        ]
        for version in items {
            #expect(container.filesystem.fileExists("/Users/fake/.config/phpmon/bin/\(version)"))
        }

        // Check a specific version
        let helperPath = "/Users/fake/.config/phpmon/bin/pm85"
        let contents = try container.filesystem.getStringFromFile(helperPath)

        #expect(writtenFiles.count == Constants.DetectedPhpVersions.count)
        #expect(contents.contains("Error: PHP 8.5 is not installed. (You can install it via PHP Monitor to update this helper file.)"))
        #expect(!contents.contains("export PATH="))
        #expect(container.filesystem.isExecutableFile(helperPath))
    }

    @Test func unchanged_helpers_are_not_rewritten() async throws {
        let container = Container.fake(files: [
            "/usr/local/bin/": .fake(.directory, readOnly: true),
            "/opt/homebrew/opt/php@8.4/bin/php": .fake(.binary)
        ])

        let firstWrite = await PhpHelper.regenerate(container, installedVersions: ["8.4"])
        let secondWrite = await PhpHelper.regenerate(container, installedVersions: ["8.4"])

        #expect(firstWrite.count == Constants.DetectedPhpVersions.count)
        #expect(secondWrite.isEmpty)
    }
}
