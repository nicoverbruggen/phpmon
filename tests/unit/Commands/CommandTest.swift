//
//  CommandTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct CommandTest {
    @Test func fake_command_outputs_can_change_while_probes_run() async {
        let command = TestableCommand(commands: ["php --version": "8.4.2"])

        await offMain {
            DispatchQueue.concurrentPerform(iterations: 32) { index in
                command.updateOutputs(["probe \(index)": "\(index)"])
                #expect(command.execute(
                    path: "probe", arguments: ["\(index)"], trimNewlines: false, withStandardError: false
                ) == "\(index)")
                #expect(command.execute(
                    path: "php", arguments: ["--version"], trimNewlines: false, withStandardError: false
                ) == "8.4.2")
            }
        }

        #expect(command.commands.count == 33)
    }

    @Test func execute_drains_output_before_waiting_for_exit() {
        let output = RealCommand().execute(
            path: "/usr/bin/perl",
            arguments: ["-e", "alarm 2; print STDOUT 'x' x 131072; print STDERR 'y' x 131072; alarm 0;"],
            trimNewlines: false,
            withStandardError: true
        )

        #expect(output.utf8.count == 262144)
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func determinePhpVersion() {
        let container = Container.real(minimal: true)

        let version = container.command.execute(
            path: container.paths.php,
            arguments: ["-v"],
            trimNewlines: false
        )

        #expect(version.contains("(cli)"))
        #expect(version.contains("NTS"))
        #expect(version.contains("built"))
        #expect(version.contains("Zend"))
    }
}
