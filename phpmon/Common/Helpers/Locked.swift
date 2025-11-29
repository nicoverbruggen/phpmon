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

 Use with care. Using structured concurrency w/ `actor` or delegating to
 `MainActor` is generally preferred, but this approach may be necessary in
 situations where adopting structured concurrency would otherwise be
 too challenging or a huge refactor.
 */
final class Locked<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

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
}
