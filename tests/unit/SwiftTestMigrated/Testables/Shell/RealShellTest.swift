//
//  RealShellTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite(.serialized)
struct RealShellTest {
    var container: Container

    init() async throws {
        // Reset to the default shell
        container = Container.real()
    }

    var Shell: ShellProtocol {
        return container.shell
    }

    @Test func system_shell_is_default() async {
        #expect(Shell is RealShell)

        let output = await Shell.pipe("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func system_shell_can_be_used_synchronously() {
        #expect(Shell is RealShell)

        let output = Shell.sync("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func system_shell_has_path() {
        let systemShell = Shell as! RealShell

        #expect(systemShell.PATH.contains(":/usr/local/bin"))
        #expect(systemShell.PATH.contains(":/usr/bin"))
    }

    @Test func system_shell_can_buffer_output() async {
        var bits: [String] = []

        let (_, shellOutput) = try! await Shell.attach(
            "php -r \"echo 'Hello world' . PHP_EOL; usleep(200); echo 'Goodbye world';\"",
            didReceiveOutput: { incoming, _ in
                bits.append(incoming)
            },
            withTimeout: 2.0
        )

        #expect(bits.contains("Hello world\n"))
        #expect(bits.contains("Goodbye world"))
        #expect("Hello world\nGoodbye world" == shellOutput.out)
    }

    @Test func system_shell_can_timeout_and_throw_error() async {
        await #expect(throws: ShellError.timedOut) {
            try await Shell.attach(
                "php -r \"sleep(1);\"",
                didReceiveOutput: { _, _ in },
                withTimeout: .seconds(0.1)
            )
        }
    }

    @Test func can_run_multiple_shell_commands_in_parallel() async throws {
        let start = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await Shell.quiet("php -r \"usleep(700000);\"") }
            group.addTask { await Shell.quiet("php -r \"usleep(700000);\"") }
            group.addTask { await Shell.quiet("php -r \"usleep(700000);\"") }
        }

        let duration = start.duration(to: .now)
        #expect(duration < .milliseconds(1500)) // Should complete in ~700ms if parallel
    }
}
