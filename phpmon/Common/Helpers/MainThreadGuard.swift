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
/// The leaf I/O primitives (`RealShell.sync`, `RealCommand.execute`, and the blocking
/// `RealFileSystem` read/write/enumerate calls) run subprocesses or synchronous file
/// I/O to completion. Those must never happen on the main thread. Today (nonisolated
/// default) they don't; once the app moves to main-actor-by-default, any call path that
/// forgets to stay off-main will beachball the UI. This guard makes that mistake loud
/// and immediate during development instead of a mysterious stall in the field.
///
/// It intentionally *logs* rather than traps: during the migration a blocking call may
/// briefly land on the main thread before its caller is moved off-main, and crashing on
/// every occurrence would make that work impossible. Once the off-main service layer is
/// complete, this can be promoted to `assertionFailure` to keep it that way.
@inline(__always)
func warnIfBlockingOnMainThread(
    _ operation: @autoclosure () -> String,
    function: StaticString = #function
) {
    #if DEBUG
    if Thread.isMainThread {
        Log.warn("[HANG-RISK] Blocking operation ran on the main thread: \(operation()) (in \(function))")
    }
    #endif
}
