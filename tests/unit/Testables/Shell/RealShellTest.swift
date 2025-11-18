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

    @Test func system_shell_is_default() async {
        #expect(container.shell is RealShell)

        let output = await container.shell.pipe("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func system_shell_can_be_used_synchronously() {
        #expect(container.shell is RealShell)

        let output = container.shell.sync("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func system_shell_has_path() {
        let systemShell = container.shell as! RealShell

        #expect(systemShell.PATH.contains(":/usr/local/bin"))
        #expect(systemShell.PATH.contains(":/usr/bin"))
    }

    @Test func system_shell_can_buffer_output() async {
        var bits: [String] = []

        let (_, shellOutput) = try! await container.shell.attach(
            "php -r \"echo 'Hello world' . PHP_EOL; usleep(500); echo 'Goodbye world';\"",
            didReceiveOutput: { incoming, _ in
                bits.append(incoming)
            },
            withTimeout: 2.0
        )

        #expect("Hello world\nGoodbye world" == shellOutput.out)
    }

    @Test func system_shell_can_timeout_and_throw_error() async {
        await #expect(throws: ShellError.timedOut) {
            try await container.shell.attach(
                "php -r \"sleep(1);\"",
                didReceiveOutput: { _, _ in },
                withTimeout: .seconds(0.1)
            )
        }
    }

    @Test func can_run_multiple_shell_commands_in_parallel() async throws {
        let start = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await container.shell.quiet("php -r \"usleep(700000);\"") }
            group.addTask { await container.shell.quiet("php -r \"usleep(700000);\"") }
            group.addTask { await container.shell.quiet("php -r \"usleep(700000);\"") }
        }

        let duration = start.duration(to: .now)
        #expect(duration < .milliseconds(2000)) // Should complete in ~700ms if parallel
    }
}
