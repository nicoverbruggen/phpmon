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

    /**
     The entire point of `runBlocking` is that, unlike a plain `nonisolated async`
     function (which under `NonisolatedNonsendingByDefault` runs on the caller's
     executor), the work is guaranteed to leave the main thread.
     */
    @MainActor
    @Test func blocking_work_never_runs_on_the_main_thread() async {
        let ranOnMainThread = await runBlocking { Thread.isMainThread }

        #expect(ranOnMainThread == false)
    }

    @MainActor
    @Test func blocking_rethrows_errors_from_the_work() async {
        struct FakeError: Error {}

        await #expect(throws: FakeError.self) {
            try await runBlocking { throw FakeError() }
        }
    }
}
