//
//  TestableConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct TestableConfigurationTest {
    @Test func intel_configuration_uses_usr_local_paths() {
        let config = TestableConfigurations.workingIntel
        let container = Container()

        container.withFakeSystemContext(architecture: config.architecture)
        container.bind(coreOnly: true)

        container.overrideFake(
            shellExpectations: config.shellOutput,
            fileSystemFiles: config.filesystem,
            commands: config.commandOutput
        )

        #expect(container.systemContext.architecture == "x86_64")
        #expect(container.paths.binPath == "/usr/local/bin")
        #expect(container.paths.brew == "/usr/local/bin/brew")
        #expect(container.paths.php == "/usr/local/bin/php")
        #expect(container.paths.valet == "/usr/local/bin/valet")
        #expect(container.paths.cellarPath == "/usr/local/Cellar")
        #expect(container.paths.tapPath == "/usr/local/homebrew/Library/Taps")
    }

    @Test func configuration_can_be_saved_as_json() async {
        let container = Container.real(minimal: true)

        // WORKING
        var configuration = TestableConfigurations.working

        try! configuration.toJson().write(
            toFile: NSHomeDirectory() + "/.phpmon_fconf_working.json",
            atomically: true,
            encoding: .utf8
        )

        // WORKING (WITHOUT VALET)
        let valetFreeConfiguration = TestableConfigurations.workingWithoutValet

        try! valetFreeConfiguration.toJson().write(
            toFile: NSHomeDirectory() + "/.phpmon_fconf_working_no_valet.json",
            atomically: true,
            encoding: .utf8
        )

        // NOT WORKING
        configuration.filesystem["/opt/homebrew/bin/php"] = nil

        try! configuration.toJson().write(
            toFile: NSHomeDirectory() + "/.phpmon_fconf_broken.json",
            atomically: true,
            encoding: .utf8
        )

        // Verify that the files were written to disk
        #expect(container.filesystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_working.json"))
        #expect(container.filesystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_working_no_valet.json"))
        #expect(container.filesystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_broken.json"))
    }

    @Test func feature_flags_can_be_saved_to_testable_configuration() throws {
        var configuration = TestableConfigurations.working
        configuration.enabledFeatures.append(.automaticServiceDiscovery)

        let decoded = try JSONDecoder().decode(
            TestableConfiguration.self,
            from: configuration.toJson().data(using: .utf8)!
        )

        #expect(decoded.enabledFeatures.contains(.automaticServiceDiscovery))
    }

    @Test func missing_feature_flags_decode_as_empty() throws {
        let data = TestableConfigurations.working.toJson().data(using: .utf8)!
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "enabledFeatures")

        let decoded = try JSONDecoder().decode(
            TestableConfiguration.self,
            from: try JSONSerialization.data(withJSONObject: json)
        )

        #expect(decoded.enabledFeatures.isEmpty)
    }
}
