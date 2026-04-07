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
        container = Container.real(minimal: true, commandTracking: false)
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func system_shell_is_default() async {
        #expect(container.shell is RealShell)

        let output = await container.shell.pipe("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func system_shell_can_be_used_synchronously() {
        #expect(container.shell is RealShell)

        let output = container.shell.sync("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func system_shell_has_path() {
        let systemShell = container.shell as! RealShell

        #expect(systemShell.PATH.contains(":/usr/local/bin"))
        #expect(systemShell.PATH.contains(":/usr/bin"))
    }

    @Test func system_shell_path_timeout_has_fallback() {
        // Simulate a broken/slow shell by passing a command that sleeps forever
        let start = ContinuousClock.now
        let path = RealShell.getPath(timeout: 1.0, shellCommand: "sleep 3600")
        let duration = start.duration(to: .now)

        // Should return the path_helper fallback (non-empty, contains system paths)
        #expect(!path.isEmpty)
        #expect(path.contains("/usr/bin"))

        // Should have timed out in roughly 0.5 seconds (allow some margin)
        #expect(duration < .seconds(1.5))
    }

    @Test func preferred_shell_path_falls_back_to_zsh_if_inaccessible() {
        #expect(validated_shell_path("/this/path/does/not/exist") == "/bin/zsh")
    }

    @Test func configured_shell_matches_dscl_usershell_output() {
        let dsclValue = system("dscl . -read ~/ UserShell | sed 's/UserShell: //'")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(configured_shell() == dsclValue)
    }

    @Test func preferred_shell_is_validated_configured_shell() {
        #expect(preferred_shell() == validated_shell_path(configured_shell()))
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func system_shell_can_buffer_output() async {
        let bits = Locked<[String]>([])

        let (_, shellOutput) = try! await container.shell.attach(
            "php -r \"echo 'Hello world' . PHP_EOL; usleep(500); echo 'Goodbye world';\"",
            didReceiveOutput: { incoming, _ in
                bits.withLock { $0.append(incoming) }
            },
            withTimeout: 2.0
        )

        #expect("Hello world\nGoodbye world" == shellOutput.out)
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func system_shell_can_timeout_and_throw_error() async {
        await #expect(throws: ShellError.timedOut) {
            try await container.shell.attach(
                "php -r \"sleep(30);\"",
                didReceiveOutput: { _, _ in },
                withTimeout: .seconds(0.1)
            )
        }
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func pipe_can_timeout_and_return_empty_output() async {
        let start = ContinuousClock.now

        let output = await container.shell.pipe("php -r \"sleep(30);\"", timeout: 0.5)

        let duration = start.duration(to: .now)

        // Should return empty output on timeout
        #expect(output.out.isEmpty)
        #expect(output.err.isEmpty)

        // Should have timed out in roughly 0.5 seconds (allow some margin)
        #expect(duration < .seconds(2))
    }

    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func pipe_without_timeout_completes_normally() async {
        let output = await container.shell.pipe("php -v")

        #expect(output.out.contains("Copyright (c) The PHP Group"))
    }

    @Test func can_run_multiple_shell_commands_in_parallel() async throws {
        let start = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await container.shell.pipe("sleep 1.5") }
            group.addTask { await container.shell.pipe("sleep 1.5") }
            group.addTask { await container.shell.pipe("sleep 1.5") }
            group.addTask { await container.shell.pipe("sleep 1.5") }
        }

        let duration = start.duration(to: .now)
        #expect(duration < .seconds(3))
    }

    @Test func exports_are_passed_as_environment_variables() {
        let systemShell = container.shell as! RealShell
        systemShell.exports = ["COMPOSER_HOME": "/path/to/directory"]

        #expect(systemShell.sync("printenv COMPOSER_HOME").out
            .trimmingCharacters(in: .whitespacesAndNewlines) == "/path/to/directory")
        #expect(systemShell.sync("echo $COMPOSER_HOME").out
            .trimmingCharacters(in: .whitespacesAndNewlines) == "/path/to/directory")
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
    @Test(.enabled(if: Binaries.hasLinkedPhp(), "Requires PHP"))
    func attach_handles_concurrent_stdout_stderr_writes_safely() async throws {
        // Create a PHP script that will output lots of text to STDOUT and STDERR.
        let phpScript = "php -r 'for ($i = 1; $i <= 500; $i++) { fwrite(STDOUT, \"stdout-$i\" . PHP_EOL); fwrite(STDERR, \"stderr-$i\" . PHP_EOL); flush(); }'"

        // Keep track of the total chunk count
        let receivedChunks = Locked<Int>(0)

        // We will now test the attach method
        let (_, shellOutput) = try await container.shell.attach(
            phpScript,
            didReceiveOutput: { _, _ in
                receivedChunks.withLock { $0 += 1 }
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

    /**
     Regression test for a timeout race in `RealShell.attach(...)`.

     It starts a shell command that:
     - writes its PID to a temp file,
     - ignores SIGTERM,
     - continuously emits stdout and stderr.

     We then call `attach` with a very short timeout and verify two things:
     1) `attach` throws `ShellError.timedOut`
     2) no additional `didReceiveOutput` callbacks are delivered after timeout
        (callback count remains stable after a short delay)

     Why this test checks a symptom instead of an app crash:
     - The real-world issue is a race condition, and races are timing-dependent.
     - The app crash (e.g. SIGTRAP in Swift runtime/concurrency) is a possible
       consequence, but not deterministic enough for a stable unit test.
     - Late callbacks after timeout are the deterministic, observable signal of
       that race window, so this test asserts the underlying unsafe behavior
       directly.

     The deferred cleanup force-kills the spawned process using the recorded PID,
     because that process intentionally ignores SIGTERM.
     */
    @Test func attach_stops_emitting_output_after_timeout() async {
        let pidFile = "/tmp/phpmon-attach-timeout-\(UUID().uuidString).pid"
        let command = "/bin/sh -c 'echo $$ > \(pidFile); trap \"\" TERM; while true; do echo stdout-line; echo stderr-line 1>&2; done'"
        let callbackCount = Locked<Int>(0)

        defer {
            if let pid = try? String(contentsOfFile: pidFile, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !pid.isEmpty {
                _ = container.shell.sync("kill -9 \(pid) 2>/dev/null || true")
            }
            try? FileManager.default.removeItem(atPath: pidFile)
        }

        await #expect(throws: ShellError.timedOut) {
            try await container.shell.attach(
                command,
                didReceiveOutput: { _, _ in
                    callbackCount.withLock { $0 += 1 }
                },
                withTimeout: .seconds(0.05)
            )
        }

        let callbackCountAtTimeout = callbackCount.value

        await delay(seconds: 0.25)

        let callbackCountAfterDelay = callbackCount.value

        // If these two match, we know no additional callbacks fired after the delay
        #expect(callbackCountAfterDelay == callbackCountAtTimeout)
    }
}
