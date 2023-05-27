//
//  Logger.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class Log {

    static var shared = Log()

    var logFilePath = "~/.config/phpmon/last_session.log"

    var logExists = false

    enum Verbosity: Int {
        case error = 1,
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
            self.logExists = FileSystem.fileExists(self.logFilePath)
        }
    }

    var verbosity: Verbosity = .warning {
        didSet {
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

    private func log(_ text: String) {
        print(text)

        if logExists && Verbosity.cli.isApplicable() {
            let logFile = URL(string: self.logFilePath.replacingTildeWithHomeDirectory)!
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(text.appending("\n").data(using: .utf8).unsafelyUnwrapped)
                fileHandle.closeFile()
            }
        }
    }
}
