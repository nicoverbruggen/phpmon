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

}
