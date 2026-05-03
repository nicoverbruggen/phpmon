//
//  RealShell+PATH.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/03/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
@preconcurrency import Dispatch

extension RealShell {
    /**
     Retrieves the user's PATH by opening an interactive shell and echoing $PATH.
     If opening the user shell times out after X seconds, a fallback is used.

     A shell command can also be injected for testing purposes, e.g. to simulate a slow shell.
     */
    internal static func getPath(
        shell: String,
        timeout: TimeInterval = 3,
        executeBeforeShellCommand: String? = nil
    ) -> String {
        // Read the system PATH. This is fast, reliable, and doesn't touch user profiles.
        let systemPath = RealShell.systemPathFromPathHelper()

        // Construct the command to fetch the PATH. If a shell command is specified, it will also be executed.
        let command: String
        if let executeBeforeShellCommand {
            command = "\(executeBeforeShellCommand); echo $PATH"
        } else {
            command = "echo $PATH"
        }

        // Kick off a regular shell. We need this once to determine the PATH.
        // Other shells invoked by the app generally don't load the user's config.
        let task = Process()
        task.launchPath = shell
        task.arguments = ["--login", "-ilc", command]

        // We redirect the standard output so we can read output later.
        let pipe = Pipe()
        task.standardOutput = pipe

        // Why queue + semaphore?
        // - `Process` completion is asynchronous (`terminationHandler`).
        // - `getPath()` runs during bootstrap and must synchronously return a String.
        // - The semaphore bridges that async completion back to this sync call site.
        // - The dedicated serial queue scopes timeout scheduling to this task instance.
        //   (No global/shared queue state is needed.)
        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.getPathQueue")
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        // Timeout path:
        // If the shell hangs while reading profile files, terminate it and unblock
        // `semaphore.wait()` so startup can continue with a safe fallback.
        let timeoutWorkItem = DispatchWorkItem {
            guard task.isRunning else { return }
            Log.warn("getPath() timed out after \(timeout)s — falling back to system PATH")

            // `terminate()` can still trigger `terminationHandler`. Clearing it here
            // avoids a second `signal()` and makes the wake-up source explicit.
            task.terminationHandler = nil
            task.terminate()
            semaphore.signal()
        }

        // Set up a timeout so that the "work" (using user's potentially slow shell) can time out
        // and we can fall back to our alternative solution. Otherwise, PHP Monitor will incur far
        // too much of a performance penalty; it's also why for most shell invocations we don't
        // use the user's profile anyway, but we do need it to know what's in the user's PATH here.
        serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        task.terminationHandler = { _ in
            timeoutWorkItem.cancel()
            result = getStringOutput(from: pipe).trimmingCharacters(in: .whitespacesAndNewlines)
            semaphore.signal()
        }

        // Attempt to fetch the PATH using the preferred shell
        do {
            try task.run()
        } catch {
            Log.warn("getPath() failed to run shell at `\(shell)`: \(error). Falling back to system PATH")

            // If the shell process cannot be started, no termination handler will fire,
            // so waiting on the semaphore would deadlock.
            return fallbackPathOrFatal(systemPath)
        }

        // Exactly one signal is expected:
        // - normal exit via `terminationHandler`, or
        // - timeout path via `timeoutWorkItem`.
        //
        // Wait until either:
        // 1) terminationHandler signals (normal process exit), or
        // 2) timeoutWorkItem signals (forced fallback path).
        semaphore.wait()

        // If the interactive shell succeeded and returned something non-empty, use it.
        // Otherwise fall back to the system PATH from path_helper.
        if let path = result, !path.isEmpty {
            return path
        }

        // Make sure the system PATH is used
        Log.warn("getPath() returned empty result, using system PATH from path_helper")
        return fallbackPathOrFatal(systemPath)
    }

    /**
     Retrieves the system PATH using /usr/libexec/path_helper (no user profile loading).
     It should always work, but some checks are done just in case.
     (This is used as a fallback.)
     */
    private static func systemPathFromPathHelper() -> String {
        let task = Process()
        task.launchPath = "/usr/libexec/path_helper"
        task.arguments = ["-s"]

        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            Log.warn("path_helper could not be launched, the fallback will be invalid: \(error)")
            return ""
        }

        task.waitUntilExit()

        let output = getStringOutput(from: pipe)

        // Output format: PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"; export PATH;
        // Extract just the PATH value between the quotes.
        if let start = output.range(of: "\"")?.upperBound,
           let end = output[start...].range(of: "\"")?.lowerBound {
            return String(output[start..<end])
        }

        return ""
    }

    /**
     The system fallback shell should normally always produce a valid fallback.
     However, if for some reason a valid shell cannot be invoked then this
     application will simply not work and a `fatalError` is expected.
     */
    private static func fallbackPathOrFatal(_ systemPath: String) -> String {
        guard !systemPath.isEmpty else {
            fatalError("System PATH was used as a fallback but is also empty")
        }

        return systemPath
    }
}
