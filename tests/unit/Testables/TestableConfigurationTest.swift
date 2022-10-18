//
//  TestableConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class TestableConfigurationTest: XCTestCase {
    func test_configuration_can_be_saved_as_json() async {
        var configuration = TestableConfigurations.working
        configuration.filesystem["/opt/homebrew/bin/php"] = nil

        let json = configuration.toJson()

        try! json.write(toFile: "/tmp/pmc_working.json", atomically: true, encoding: .utf8)
        try! json.write(toFile: "/tmp/pmc_broken.json", atomically: true, encoding: .utf8)
    }
}

