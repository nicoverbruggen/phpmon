//
//  Locked.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 A thread-safe wrapper for a value that can be accessed from multiple threads.
 
 Uses `NSLock` internally to ensure only one thread can read or write at a time,
 preventing race conditions where two threads might try to access or modify
 the value simultaneously.
 
 ## Usage
 
 ```swift
 private let _counter = Locked<Int>(0)
 var counter: Int {
     get { _counter.value }
     set { _counter.value = newValue }
 }
 ```

 Without locking, if Thread A reads a value while Thread B is writing to it,
 Thread A might see a partially-written or inconsistent state, leading to crashes
 or corrupted data. The lock ensures operations happen one at a time.

 ## Caveats

 - `NSLock` is non-reentrant: nested access to the same instance from within
   `withLock` or the `value` accessors — e.g. reading `value` inside a `withLock`
   body, or setting `value` from another `withLock` on the same `Locked` — will
   deadlock.
 - Compound assignments like `locked.value += x` are a get followed by a set:
   two separate critical sections, not an atomic read-modify-write. Another
   thread can interleave between the read and the write, losing updates. Use
   `withLock { $0 += x }` for read-modify-write operations.

 Use with care. Using structured concurrency w/ `actor` or delegating to
 `MainActor` is generally preferred, but this approach may be necessary in
 situations where adopting structured concurrency would otherwise be
 too challenging or a huge refactor.

 `nonisolated`: this is the app's thread-safe primitive. Its `NSLock`-guarded `value`
 and `withLock` must be usable from any isolation domain (off-main services, actors,
 the main actor). Without `nonisolated` these members would inherit the main actor
 under main-actor-by-default and defeat the whole purpose of the type.
 */
nonisolated final class Locked<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    /**
     Reads or replaces the value, each under its own lock acquisition.
     Not suitable for read-modify-write (`value += x`): use `withLock` instead.
     Accessing `value` from within a `withLock` body deadlocks (non-reentrant).
     */
    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    /**
     Runs `body` with exclusive access to the value: the way to perform an
     atomic read-modify-write. The body must not touch this same `Locked`
     instance again (via `value` or `withLock`) — the lock is non-reentrant
     and doing so deadlocks.
     */
    @discardableResult
    func withLock<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&_value)
    }
}
