//
//  Logger.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import os

// `nonisolated` + `Sendable`: Log is called from the main actor and from arbitrary background
// threads. All mutable state (`verbosity`, `logExists`) lives inside an `OSAllocatedUnfairLock`
// (Apple's `Sendable` lock, available on the app's macOS 13.5 deployment target), so the class
// is genuinely data-race-free and can conform to `Sendable` without `@unchecked`. File appends
// happen inside the same lock-protected region, so concurrent log lines cannot interleave.
// When the deployment target reaches macOS 15 this lock can become the standard-library `Mutex`.
nonisolated final class Log: Sendable {
    static let shared = Log()

    let logFilePath = "~/.config/phpmon/last_session.log"

    /// The mutable state of the logger, only ever accessed via the lock below.
    private struct MutableState {
        var verbosity: Verbosity = .warning
        var logExists = false
    }

    private let state = OSAllocatedUnfairLock(initialState: MutableState())

    enum Verbosity: Int {
        case always = 0,
             error = 1,
             warning = 2,
             info = 3,
             performance = 4,
             cli = 5

        public func isApplicable() -> Bool {
            return Log.shared.verbosity.rawValue >= self.rawValue
        }
    }

    public func prepareLogFile() {
        if !isRunningTests && Verbosity.cli.isApplicable() {
            system_quiet("mkdir -p ~/.config/phpmon 2> /dev/null")
            system_quiet("rm ~/.config/phpmon/last_session.log 2> /dev/null")
            system_quiet("touch ~/.config/phpmon/last_session.log 2> /dev/null")
            let exists = App.shared.container.filesystem.fileExists(self.logFilePath)
            state.withLock { $0.logExists = exists }
        }
    }

    var verbosity: Verbosity {
        get { state.withLock { $0.verbosity } }
        set {
            state.withLock { $0.verbosity = newValue }
            self.prepareLogFile()
        }
    }

    static func err(_ item: Any) {
        if Verbosity.error.isApplicable() {
            Log.shared.log("[E] \(item)")
        }
    }

    static func warn(_ item: Any) {
        if Verbosity.warning.isApplicable() {
            Log.shared.log("[W] \(item)")
        }
    }

    static func info(_ item: Any) {
        if Verbosity.info.isApplicable() {
            Log.shared.log("\(item)")
        }
    }

    static func perf(_ item: Any) {
        if Verbosity.performance.isApplicable() {
            Log.shared.log("[P] \(item)")
        }
    }

    static func separator(as verbosity: Verbosity = .info) {
        if verbosity.isApplicable() {
            Log.shared.log("==================================")
        }
    }

    static func line(as verbosity: Verbosity = .info) {
        if verbosity.isApplicable() {
            Log.shared.log("----------------------------------")
        }
    }

    static func always(_ text: String) {
        Log.shared.log(text)
    }

    private func log(_ text: String) {
        if isRunningSwiftUIPreview {
            return
        }

        print(text)

        // The check and the append happen inside a single lock-protected region: the
        // open-seek-write-close sequence is not atomic on its own, so serializing it here
        // prevents concurrent log lines from interleaving or clobbering one another.
        // (Reading `verbosity` directly avoids re-entering the non-reentrant lock via
        // `Verbosity.isApplicable()`.)
        state.withLock { state in
            guard state.logExists && state.verbosity.rawValue >= Verbosity.cli.rawValue else {
                return
            }

            let logFile = URL(string: self.logFilePath.replacingTildeWithHomeDirectory)!
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(text.appending("\n").data(using: .utf8).unsafelyUnwrapped)
                fileHandle.closeFile()
            }
        }
    }
}
