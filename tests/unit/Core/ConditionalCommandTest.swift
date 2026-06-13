//
//  ConditionalCommandTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct ConditionalCommandTest {
    @Test func includes_commands_by_default() {
        let commands: [ConditionalCommand] = [
            .command("brew tap shivammathur/php"),
            .command("brew tap shivammathur/extensions"),
            .command("brew install shivammathur/php/php")
        ]

        #expect(commands.included == [
            "brew tap shivammathur/php",
            "brew tap shivammathur/extensions",
            "brew install shivammathur/php/php"
        ])
        #expect(commands.chained == "brew tap shivammathur/php "
            + "&& brew tap shivammathur/extensions "
            + "&& brew install shivammathur/php/php")
    }

    @Test func drops_trust_commands_when_trust_is_unsupported() {
        let supportsTrust = false

        let commands: [ConditionalCommand] = [
            .command("brew tap shivammathur/php"),
            .command("brew trust --tap shivammathur/php", when: supportsTrust),
            .command("brew install shivammathur/php/php")
        ]

        #expect(commands.included == [
            "brew tap shivammathur/php",
            "brew install shivammathur/php/php"
        ])
        #expect(commands.chained == "brew tap shivammathur/php && brew install shivammathur/php/php")
    }

    @Test func keeps_trust_commands_when_trust_is_supported() {
        let supportsTrust = true

        let commands: [ConditionalCommand] = [
            .command("brew tap shivammathur/php"),
            .command("brew trust --tap shivammathur/php", when: supportsTrust),
            .command("brew install shivammathur/php/php")
        ]

        #expect(commands.included == [
            "brew tap shivammathur/php",
            "brew trust --tap shivammathur/php",
            "brew install shivammathur/php/php"
        ])
    }

    @Test func selects_the_secure_variant_for_the_valet_proxy_toggle() {
        // Mirrors `ValetInteractor.toggleSecure` when an unsecured proxy is toggled on.
        let originalSecureStatus = false

        let commands: [ConditionalCommand] = [
            .command("valet unproxy example.test"),
            .command("valet proxy example.test http://127.0.0.1:9000", when: originalSecureStatus),
            .command("valet proxy example.test http://127.0.0.1:9000 --secure", when: !originalSecureStatus)
        ]

        #expect(commands.included == [
            "valet unproxy example.test",
            "valet proxy example.test http://127.0.0.1:9000 --secure"
        ])
        #expect(commands.chained == "valet unproxy example.test "
            + "&& valet proxy example.test http://127.0.0.1:9000 --secure")
    }

    @Test func handles_a_single_included_command_without_separators() {
        let commands: [ConditionalCommand] = [.command("brew link php")]

        #expect(commands.included == ["brew link php"])
        #expect(commands.chained == "brew link php")
    }

    @Test func yields_nothing_when_all_commands_are_excluded() {
        let commands: [ConditionalCommand] = [
            .command("brew trust --tap shivammathur/php", when: false),
            .command("brew trust --tap shivammathur/extensions", when: false)
        ]

        #expect(commands.included.isEmpty)
        #expect(commands.chained == "")
    }

    @Test func handles_an_empty_command_list() {
        let commands: [ConditionalCommand] = []

        #expect(commands.included.isEmpty)
        #expect(commands.chained == "")
    }
}
