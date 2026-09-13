//
//  RunBlocking.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

/// Runs synchronous work on Dispatch while the calling Swift task is suspended.
///
/// Blocking work must leave both the main actor and Swift's cooperative pool.
/// `@concurrent` only leaves the actor; blocking its worker can prevent queued
/// work from running, including work needed to release the blocked worker.
///
/// Return Sendable data and construct UI models on the main actor, as in
/// `PhpInstallation.Probe`. Cancellation does not interrupt the synchronous work;
/// the caller waits for its result. The closure does not inherit task-local state.
@discardableResult
nonisolated func runBlocking<T: Sendable, Failure: Error>(
    _ work: @escaping @Sendable () throws(Failure) -> T
) async throws(Failure) -> T {
    let result: Result<T, Failure> = await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            continuation.resume(returning: Result(catching: work))
        }
    }
    return try result.get()
}
