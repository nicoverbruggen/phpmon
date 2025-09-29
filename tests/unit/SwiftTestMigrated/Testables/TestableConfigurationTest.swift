//
//  TestableConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct TestableConfigurationTest {
    @Test func configuration_can_be_saved_as_json() async {
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
        #expect(FileSystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_working.json"))
        #expect(FileSystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_working_no_valet.json"))
        #expect(FileSystem.fileExists(NSHomeDirectory() + "/.phpmon_fconf_broken.json"))
    }
}
