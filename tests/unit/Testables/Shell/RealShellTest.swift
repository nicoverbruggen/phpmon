//
//  RealShellTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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

    @Test func attach_handles_concurrent_stdout_stderr_writes_safely() async throws {
        // This test verifies that concurrent writes to output.out and output.err
        // from multiple readability handlers don't cause data races or crashes.
        // Without the serial queue, rapid interleaved output causes undefined behavior.

        let script = """
        for i in {1..200}; do
            echo "stdout-$i" >&1
            echo "stderr-$i" >&2
        done
        """

        var receivedChunks = 0
        let (_, shellOutput) = try await container.shell.attach(
            script,
            didReceiveOutput: { _, _ in
                receivedChunks += 1
            },
            withTimeout: 5.0
        )

        // Verify all output was captured without corruption
        let stdoutLines = shellOutput.out
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
        let stderrLines = shellOutput.err
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        #expect(stdoutLines.count == 200)
        #expect(stderrLines.count == 200)

        // Verify content integrity - each line should match the pattern
        for i in 1...200 {
            #expect(stdoutLines.contains("stdout-\(i)"))
            #expect(stderrLines.contains("stderr-\(i)"))
        }
    }
}
