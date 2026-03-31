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
     If opening the user shell times out after 10 seconds, a fallback is used.

     A shell command can also be injected for testing purposes, e.g. to simulate a slow shell.
     */
    internal static func getPath(timeout: TimeInterval = 10, shellCommand: String? = nil) -> String {
        // Read the system PATH. This is fast, reliable, and doesn't touch user profiles.
        let systemPath = RealShell.systemPathFromPathHelper()

        // After doing that, use the user's preferred shell to load potential, other PATH inclusions.
        // This information is used to inform the user about the helper includes.
        let userShell = preferred_shell()

        // Construct the command to fetch the PATH. If a shell command is specified, it will also be executed.
        let command: String
        if let shellCommand {
            command = "\(shellCommand); echo $PATH"
        } else {
            command = "echo $PATH"
        }

        let task = Process()
        task.launchPath = userShell
        task.arguments = ["--login", "-ilc", command]

        let pipe = Pipe()
        task.standardOutput = pipe

        let serialQueue = DispatchQueue(label: "com.nicoverbruggen.phpmon.getPathQueue")
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        let timeoutWorkItem = DispatchWorkItem {
            guard task.isRunning else { return }
            Log.warn("getPath() timed out after \(timeout)s — falling back to system PATH")
            task.terminationHandler = nil
            task.terminate()
            semaphore.signal()
        }

        serialQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        task.terminationHandler = { _ in
            timeoutWorkItem.cancel()
            result = getStringOutput(from: pipe).trimmingCharacters(in: .whitespacesAndNewlines)
            semaphore.signal()
        }

        task.launch()
        semaphore.wait()

        // If the interactive shell succeeded and returned something non-empty, use it.
        // Otherwise fall back to the system PATH from path_helper.
        if let path = result, !path.isEmpty {
            return path
        }

        Log.warn("getPath() returned empty result, using system PATH from path_helper")
        return systemPath
    }

    /**
     Retrieves the system PATH using /usr/libexec/path_helper (no user profile loading).
     This is used as a fallback.
     */
    private static func systemPathFromPathHelper() -> String {
        let task = Process()
        task.launchPath = "/usr/libexec/path_helper"
        task.arguments = ["-s"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
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
}
