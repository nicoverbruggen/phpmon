//
//  PhpConfigurationFileTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

class PhpConfigurationFileTest {
    var container: Container

    init() {
        self.container = Container.real(minimal: true)
    }

    static var phpIniFileUrl: URL {
        return TestBundle.url(forResource: "php", withExtension: "ini")!
    }

    @Test func can_load_extension() throws {
        let iniFile = PhpConfigurationFile.from(container, filePath: Self.phpIniFileUrl.path)

        #expect(iniFile != nil)
        #expect(!iniFile!.extensions.isEmpty)
    }

    @Test func can_check_key_existence() throws {
        let iniFile = PhpConfigurationFile.from(container, filePath: Self.phpIniFileUrl.path)!

        #expect(iniFile.has(key: "error_reporting"))
        #expect(iniFile.has(key: "display_errors"))
        #expect(false == iniFile.has(key: "my_unknown_key"))
    }

    @Test func can_check_key_value() throws {
        let iniFile = PhpConfigurationFile.from(container, filePath: Self.phpIniFileUrl.path)!

        #expect(iniFile.get(for: "error_reporting") != nil)
        #expect(iniFile.get(for: "error_reporting") == "E_ALL")

        #expect(iniFile.get(for: "display_errors") != nil)
        #expect(iniFile.get(for: "display_errors") == "On")
    }

    @Test func can_customize_configuration_value() async throws {
        let destination = Utility
            .copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!

        let configurationFile = PhpConfigurationFile.from(container, filePath: destination.path)!

        // 0. Verify the original value
        #expect(configurationFile.get(for: "error_reporting") == "E_ALL")

        // 1. Change the value
        try! await configurationFile.replace(
            key: "error_reporting",
            value: "E_ALL & ~E_DEPRECATED & ~E_STRICT"
        )
        #expect(
            configurationFile.get(for: "error_reporting") ==
            "E_ALL & ~E_DEPRECATED & ~E_STRICT"
        )

        // 2. Ensure that same key and value doesn't break subsequent saves
        try! await configurationFile.replace(
            key: "error_reporting",
            value: "error_reporting"
        )
        #expect(configurationFile.get(for: "error_reporting") == "error_reporting")

        // 3. Verify subsequent saves weren't broken
        try! await configurationFile.replace(
            key: "error_reporting",
            value: "E_ALL"
        )
        #expect(configurationFile.get(for: "error_reporting") == "E_ALL")
    }

    @Test func fake_configuration_edits_never_touch_a_real_file_at_the_same_path() async throws {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("phpmon-config-isolation-\(UUID().uuidString).ini")
        let realContents = "memory_limit = 128M\n"
        try realContents.write(to: destination, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: destination) }

        let fake = Container.fake(files: [
            destination.path: .fake(.text, "memory_limit = 512M\n")
        ])
        let configurationFile = try #require(PhpConfigurationFile.from(fake, filePath: destination.path))

        try await configurationFile.replace(key: "memory_limit", value: "1024M")

        #expect(try String(contentsOf: destination, encoding: .utf8) == realContents)
        #expect(try fake.filesystem.getStringFromFile(destination.path) == "memory_limit = 1024M\n")
        #expect(configurationFile.get(for: "memory_limit") == "1024M")

        try fake.filesystem.writeAtomicallyToFile(destination.path, content: "memory_limit = 256M\n")
        await configurationFile.reload()
        #expect(configurationFile.get(for: "memory_limit") == "256M")
    }

    @Test func overlapping_edits_preserve_every_changed_key() async throws {
        let path = "/private/tmp/phpmon-overlapping-config-\(UUID().uuidString).ini"
        let contents = (0..<10).map { "setting_\($0) = 0" }.joined(separator: "\n")
        let fake = Container.fake(files: [path: .fake(.text, contents)])
        let configurationFile = try #require(PhpConfigurationFile.from(fake, filePath: path))

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    try await configurationFile.replace(key: "setting_\(index)", value: "1")
                }
            }
            try await group.waitForAll()
        }

        let saved = try #require(PhpConfigurationFile.from(fake, filePath: path))
        for index in 0..<10 {
            #expect(saved.get(for: "setting_\(index)") == "1")
            #expect(configurationFile.get(for: "setting_\(index)") == "1")
        }
    }

}
