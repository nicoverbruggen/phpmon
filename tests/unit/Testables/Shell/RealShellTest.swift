//
//  RealShellTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct RealShellTest {
    var container: Container

    init() async throws {
        // Reset to the default shell
        container = Container.real(minimal: true)
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

    /**
     This test verifies that concurrent writes to `output.out` and `output.err`
     from multiple readability handlers don't cause data races or crashes,
     and that the output is correct (for both stdout and stderr output).

     When Thread Sanitizer is enabled, this will also check if any potential
     data races occur. None should, at this point. You can enable the
     Thread Sanitizer by editing the Test Plan's Configurations.

     This test was added specifically to diagnose and fix one such reported
     data race, which was fixed by adding a serial queue to the shell's
     `attach()` method, since the readability handlers actually run
     on separate threads.
     */
    @Test func attach_handles_concurrent_stdout_stderr_writes_safely() async throws {
        // Create a PHP script that will output lots of text to STDOUT and STDERR.
        let phpScript = "php -r 'for ($i = 1; $i <= 500; $i++) { fwrite(STDOUT, \"stdout-$i\" . PHP_EOL); fwrite(STDERR, \"stderr-$i\" . PHP_EOL); flush(); }'"

        // Keep track of the total chunk count
        var receivedChunks = 0

        // We will now test the attach method
        let (_, shellOutput) = try await container.shell.attach(
            phpScript,
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

        #expect(stdoutLines.count == 500)
        #expect(stderrLines.count == 500)

        // Verify content integrity
        for i in 1...200 {
            #expect(stdoutLines.contains("stdout-\(i)"))
            #expect(stderrLines.contains("stderr-\(i)"))
        }
    }
}
