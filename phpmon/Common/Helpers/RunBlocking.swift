//
//  RunBlocking.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

/// Runs blocking work on the concurrent thread pool.
///
/// With approachable concurrency, `nonisolated async` inherits the caller's
/// executor. `@concurrent` is required to leave the main actor.
///
/// Return Sendable data and construct UI models on the main actor, as in
/// `PhpInstallation.Probe`.
@concurrent
@discardableResult
nonisolated func runBlocking<T: Sendable>(
    _ work: @Sendable () throws -> T
) async rethrows -> T {
    try work()
}
