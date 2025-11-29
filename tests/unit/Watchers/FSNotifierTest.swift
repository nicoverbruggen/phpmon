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
        let debouncer = Debouncer()

        // Create notifier
        let notifier = FSNotifier(
            for: testFile,
            eventMask: .write,
            onChange: {
                Task {
                    // Debouncer is an actor so this is allowed
                    await debouncer.debounce(for: 1.0) {
                        eventFired.value += 1
                    }
                }
            }
        )

        defer {
            notifier.terminate()
        }

        // Modify the file, twice
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)

        // Wait for the event to fire, verify it fired ONCE after 1 second debounce
        await delay(seconds: 1.2)
        #expect(eventFired.value == 1)

        // Try to write again (after debounce timing)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)

        // Verify after another second, our second write is actually noted
        await delay(seconds: 1.2)
        #expect(eventFired.value == 2)
    }
}
