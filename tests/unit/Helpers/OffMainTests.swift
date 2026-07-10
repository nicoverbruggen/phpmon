//
//  OffMainTests.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("offMain Behavior")
struct OffMainTests {

    /**
     The entire point of `offMain` is that, unlike a plain `nonisolated async`
     function (which under `NonisolatedNonsendingByDefault` runs on the caller's
     executor), the work is guaranteed to leave the main thread.
     */
    @MainActor
    @Test func off_main_work_never_runs_on_the_main_thread() async {
        let ranOnMainThread = await offMain { Thread.isMainThread }

        #expect(ranOnMainThread == false)
    }

    @MainActor
    @Test func off_main_returns_the_result_of_the_work() async {
        let value = await offMain { (1...5).reduce(0, +) }

        #expect(value == 15)
    }

    @MainActor
    @Test func off_main_rethrows_errors_from_the_work() async {
        struct FakeError: Error {}

        await #expect(throws: FakeError.self) {
            try await offMain { throw FakeError() }
        }
    }
}
