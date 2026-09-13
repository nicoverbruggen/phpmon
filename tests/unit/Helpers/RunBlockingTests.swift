//
//  RunBlockingTests.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("runBlocking Behavior")
struct RunBlockingTests {

    @MainActor
    @Test func blocking_work_never_runs_on_the_main_thread() async {
        let ranOnMainThread = await runBlocking { Thread.isMainThread }

        #expect(ranOnMainThread == false)
    }

    @Test func blocking_work_does_not_occupy_a_swift_task() async {
        // Leaving the main actor is insufficient: a cooperative worker can
        // deadlock when it blocks waiting for other queued work.
        let hasCurrentTask = await runBlocking {
            withUnsafeCurrentTask { $0 != nil }
        }

        #expect(hasCurrentTask == false)
    }

    @Test func blocking_work_allows_other_tasks_to_make_progress() async {
        let (completed, hasSwiftTask, task) = await runBlocking {
            let hasSwiftTask = withUnsafeCurrentTask { $0 != nil }
            let finished = DispatchGroup()
            finished.enter()
            let task = Task.detached(priority: .userInitiated) { finished.leave() }
            // Bound the wait so a regression fails instead of hanging the suite.
            return (finished.wait(timeout: .now() + 5) == .success, hasSwiftTask, task)
        }

        await task.value
        // Spare workers can hide starvation, so also check the execution context.
        #expect(!hasSwiftTask)
        #expect(completed)
    }

    @Test func concurrent_shell_reads_complete() async {
        let shell = RealShell(binPath: "/usr/bin", preferredShell: "/bin/zsh")
        await withTaskGroup(of: ShellOutput.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    await runBlocking { shell.sync("printf stdout; printf stderr >&2") }
                }
            }
            for await output in group {
                #expect(output.out == "stdout")
                #expect(output.err == "stderr")
            }
        }
    }

    @MainActor
    @Test func blocking_rethrows_errors_from_the_work() async {
        struct FakeError: Error {}

        await #expect(throws: FakeError.self) {
            try await runBlocking { throw FakeError() }
        }
    }
}
