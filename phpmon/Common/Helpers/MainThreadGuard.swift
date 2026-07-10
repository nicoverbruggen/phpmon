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
/// It intentionally *logs* rather than traps: a blocking call may briefly land on the
/// main thread while a caller is being reworked, and crashing on every occurrence would
/// make that work impossible. Now that the detection pipeline runs off-main, this can
/// eventually be promoted to `assertionFailure` to keep it that way.
@inline(__always)
nonisolated func warnIfBlockingOnMainThread(
    _ operation: @autoclosure () -> String,
    function: StaticString = #function
) {
    #if DEBUG
    if Thread.isMainThread {
        Log.warn("[HANG-RISK] Blocking operation ran on the main thread: \(operation()) (in \(function))")
    }
    #endif
}
