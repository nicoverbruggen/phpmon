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

    enum Verbosity: Int {
        case error = 1,
             warning = 2,
             info = 3,
             performance = 4

        public func isApplicable() -> Bool {
            return Log.shared.verbosity.rawValue >= self.rawValue
        }
    }

    var verbosity: Verbosity = .warning

    static func err(_ item: Any) {
        if Verbosity.error.isApplicable() {
            print("[E] \(item)")
        }
    }

    static func warn(_ item: Any) {
        if Verbosity.warning.isApplicable() {
            print("[W] \(item)")
        }
    }

    static func info(_ item: Any) {
        if Verbosity.info.isApplicable() {
            print("\(item)")
        }
    }

    static func perf(_ item: Any) {
        if Verbosity.performance.isApplicable() {
            print("[P] \(item)")
        }
    }

    static func separator(as verbosity: Verbosity = .info) {
        if verbosity.isApplicable() {
            print("==================================")
        }
    }

    static func line(as verbosity: Verbosity = .info) {
        if verbosity.isApplicable() {
            print("----------------------------------")
        }
    }

}
