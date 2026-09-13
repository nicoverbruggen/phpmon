//
//  LoggerTests.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/07/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("Logger Thread Safety", .serialized)
struct LoggerTests {

    @Test func verbosity_filtering_behaves_as_expected() {
        Log.shared.verbosity = .error

        #expect(Log.Verbosity.always.isApplicable())
        #expect(Log.Verbosity.error.isApplicable())
        #expect(!Log.Verbosity.warning.isApplicable())
        #expect(!Log.Verbosity.info.isApplicable())
        #expect(!Log.Verbosity.performance.isApplicable())

        Log.shared.verbosity = .info

        #expect(Log.Verbosity.warning.isApplicable())
        #expect(Log.Verbosity.info.isApplicable())
        #expect(!Log.Verbosity.performance.isApplicable())

        // Restore the default so other tests see the logger in its usual state
        Log.shared.verbosity = .warning
    }

    @Test func concurrent_verbosity_changes_and_logging_are_thread_safe() async {
        let iterations = 500

        // Hammer the logger from many tasks at once: half of them flip the verbosity
        // while the other half read it (via `isApplicable`) and emit log lines. Before
        // `Log` was lock-protected this was a data race; now it must simply not crash.
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    if i % 2 == 0 {
                        Log.shared.verbosity = (i % 4 == 0) ? .error : .info
                    } else {
                        // `.performance` is never applicable while flipping between
                        // `.error` and `.info`, so this exercises the read path and
                        // `log()` without spamming the test output.
                        Log.perf("logger-test-\(i)")
                        _ = Log.Verbosity.info.isApplicable()
                        _ = Log.shared.verbosity
                    }
                }
            }
        }

        // After the dust settles, filtering must still behave deterministically
        Log.shared.verbosity = .error
        #expect(Log.Verbosity.error.isApplicable())
        #expect(!Log.Verbosity.info.isApplicable())

        Log.shared.verbosity = .warning
    }
}
