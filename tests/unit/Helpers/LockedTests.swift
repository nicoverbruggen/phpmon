//
//  LockedTests.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("Locked Thread Safety")
struct LockedTests {

    @Test("Reading and writing from a single thread works correctly")
    func singleThreadReadWrite() {
        let locked = Locked<Int>(0)

        locked.value = 42
        #expect(locked.value == 42)

        locked.value = 100
        #expect(locked.value == 100)
    }

    @Test("Concurrent writes do not cause data races")
    func concurrentWritesAreThreadSafe() async {
        let locked = Locked<Int>(0)
        let iterations = 1000

        // Spawn many concurrent tasks that all increment the counter
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    // Read, increment, write — each step is individually locked
                    // Note: This is NOT atomic, but it shouldn't crash
                    let current = locked.value
                    locked.value = current + 1
                }
            }
        }

        // The final value may not be exactly `iterations` because read-then-write
        // is not atomic, but we should not crash and should have a reasonable value
        #expect(locked.value > 0, "Value should have been incremented")
        #expect(locked.value <= iterations, "Value should not exceed iterations")
    }

    @Test("Concurrent reads and writes do not crash")
    func concurrentReadsAndWritesDoNotCrash() async {
        let locked = Locked<[String]>([])
        let iterations = 500

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    locked.value = ["item-\(i)"]
                }
            }

            // Readers
            for _ in 0..<iterations {
                group.addTask {
                    _ = locked.value.first
                }
            }
        }

        // If we get here without crashing, the test passes
        #expect(locked.value.count <= 1, "Array should have 0 or 1 elements")
    }

    @Test("Dictionary access is thread-safe")
    func dictionaryAccessIsThreadSafe() async {
        let locked = Locked<[String: Int]>([:])
        let iterations = 100

        await withTaskGroup(of: Void.self) { group in
            // Multiple tasks replacing the entire dictionary
            for i in 0..<iterations {
                group.addTask {
                    locked.value = ["key": i]
                }
            }

            // Multiple tasks reading from the dictionary
            for _ in 0..<iterations {
                group.addTask {
                    _ = locked.value["key"]
                }
            }
        }

        // Should have exactly one key if any writes completed
        #expect(locked.value.keys.count <= 1)
    }

    @Test("Stress test with high concurrency")
    func stressTestHighConcurrency() async {
        let locked = Locked<Int>(0)
        let taskCount = 10
        let incrementsPerTask = 100

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    for _ in 0..<incrementsPerTask {
                        // Full replacement (not increment) to avoid needing atomic read-modify-write
                        let newValue = Int.random(in: 0..<1000)
                        locked.value = newValue
                        _ = locked.value
                    }
                }
            }
        }

        // If we reach here without EXC_BAD_ACCESS or data corruption, we're good
        let finalValue = locked.value
        #expect(finalValue >= 0 && finalValue < 1000, "Value should be within expected range")
    }
}
