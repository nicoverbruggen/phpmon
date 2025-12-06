//
//  FSNotifierTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct FSNotifierTest {

    @Test func notifier_fires_when_file_is_modified() async throws {
        // Create a temporary file to monitor
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("fs_notifier_test_\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: testFile.path, contents: nil)

        // Our variable to keep track of
        let eventFired = Locked<Int>(0)

        // Our debouncer
        let debouncer = Debouncer()

        // Set up the notifier
        let notifier = FSNotifier(for: testFile, eventMask: .write, onChange: {
            Task { await debouncer.debounce(for: 1.0) {
                eventFired.value += 1
            }}
        })

        // Cleanup for later
        defer {
            try? FileManager.default.removeItem(at: testFile)
            notifier.terminate()
        }

        // Modify the file, twice, debounce should work
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

    @Test func notifier_suspends_and_resumes_correctly() async throws {
        // Create a temporary file to monitor
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("fs_notifier_test_\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: testFile.path, contents: nil)

        // Our variable to keep track of
        let eventFired = Locked<Int>(0)

        // Create notifier
        let notifier = FSNotifier(for: testFile, eventMask: .write, onChange: {
            Task { eventFired.value += 1 }
        })

        // Cleanup for later
        defer {
            try? FileManager.default.removeItem(at: testFile)
            notifier.terminate()
        }

        // Modify the file, twice
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        await delay(seconds: 0.2)
        #expect(eventFired.value == 1)

        // Try to write again (after debounce timing)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        await delay(seconds: 0.2)
        #expect(eventFired.value == 2)

        // Now, we will suspend
        await notifier.suspend()

        // Despite writing to the file, our event did not fire
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        await delay(seconds: 0.2)
        #expect(eventFired.value == 2)

        // Now, we will resume
        await notifier.resume()

        // Our event should have fired again
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        await delay(seconds: 0.2)
        #expect(eventFired.value == 3)
    }
}
