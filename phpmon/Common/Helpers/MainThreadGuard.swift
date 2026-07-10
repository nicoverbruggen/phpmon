//
//  MainThreadGuard.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

/// A debug-only guard that flags when a blocking operation is executed on the main
/// thread — the fingerprint of a UI hang.
///
/// The leaf I/O primitives (`RealShell.sync`, `RealCommand.execute`, the blocking
/// `RealFileSystem` read/write/enumerate calls, and the lazy PATH resolution) run
/// subprocesses or synchronous file I/O to completion. Those must never happen on the
/// main thread: under main-actor-by-default, any call path that forgets to hop off-main
/// (via `offMain` or an `@concurrent` function) will beachball the UI. This guard makes
/// that mistake loud and immediate during development instead of a mysterious stall in
/// the field.
///
/// Now that the entire detection/scanning pipeline runs off-main, this guard **traps**
/// (`assertionFailure`) in debug builds: blocking the main thread is a hard failure, not
/// a log line. The warning is still logged first so the offending operation is visible
/// in the console before the assertion fires. Unit tests are exempt — they deliberately
/// exercise the blocking leaf APIs (e.g. `RealShell.sync`) from main-actor-isolated
/// test functions, which is fine in a test runner.
@inline(__always)
nonisolated func warnIfBlockingOnMainThread(
    _ operation: @autoclosure () -> String,
    function: StaticString = #function
) {
    #if DEBUG
    if Thread.isMainThread {
        let message = "[HANG-RISK] Blocking operation ran on the main thread: \(operation()) (in \(function))"
        Log.warn(message)

        if !isRunningTests {
            assertionFailure(message)
        }
    }
    #endif
}
