//
//  TestableConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class TestableConfigurationTest: XCTestCase {
    func test_configuration_can_be_saved_as_json() async {
        var configuration = TestableConfigurations.working
        
        try! configuration.toJson().write(
            toFile: NSHomeDirectory() + "/.phpmon_fconf_working.json",
            atomically: true,
            encoding: .utf8
        )

        configuration.filesystem["/opt/homebrew/bin/php"] = nil

        try! configuration.toJson().write(
            toFile: NSHomeDirectory() + "/.phpmon_fconf_broken.json",
            atomically: true,
            encoding: .utf8
        )
    }
}

