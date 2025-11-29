//
//  FSNotifierTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite(.serialized)
struct FSNotifierTest {
    /**
     This test verifies that FSNotifier fires the onChange callback when a file is modified.
     */
    @Test func notifier_fires_when_file_is_modified_and_debounces_correctly() async throws {
        // Create a temporary file to monitor
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("fs_notifier_test_\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: testFile.path, contents: nil)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        let eventFired = Locked<Int>(0)

        // Create notifier
        let notifier = FSNotifier(
            for: testFile,
            eventMask: .write,
            onChange: {
                eventFired.value += 1
            }
        )

        defer {
            notifier.terminate()
        }

        // Modify the file, twice
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)

        // Wait for the event to fire, verify it fired ONCE (not TWICE)
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        #expect(eventFired.value == 1)

        // Try to write again (after debounce timing)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)

        // Verify our event fired AGAIN after 0.2 seconds
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        #expect(eventFired.value == 2)
    }
}
