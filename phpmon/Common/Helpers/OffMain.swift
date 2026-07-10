//
//  OffMain.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

/// Runs a blocking operation on the concurrent thread pool, guaranteeing it
/// never executes on the caller's executor.
///
/// Because the project enables approachable concurrency
/// (`NonisolatedNonsendingByDefault`), a plain `nonisolated async` function
/// still runs on the *caller's* executor — for main-actor callers that is the
/// main thread. `@concurrent` (SE-0461) forces this function onto the
/// concurrent pool instead.
///
/// Use this to wrap the blocking leaf APIs (`shell.sync`, `command.execute`,
/// and the blocking `filesystem` calls) when calling from the main actor:
///
/// ```
/// let contents = try await offMain { try container.filesystem.getStringFromFile(path) }
/// ```
///
/// The result must be `Sendable`, since it crosses back to the caller's
/// isolation. Model objects that aren't `Sendable` should be built on the
/// main actor from the `Sendable` data returned here (see `PhpInstallation.Probe`).
@concurrent
@discardableResult
nonisolated func offMain<T: Sendable>(
    _ work: @Sendable () throws -> T
) async rethrows -> T {
    try work()
}
