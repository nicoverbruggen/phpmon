//
//  Logger.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class Log {
    
    enum Verbosity: Int {
        case error = 1,
             info = 2,
             warning = 3,
             performance = 4
        
        public func isApplicable() -> Bool {
            return Log.shared.verbosity.rawValue >= self.rawValue
        }
    }
    
    static var shared = Log()
    
    var verbosity: Verbosity = .info
    
    static func info(_ item: Any) {
        if Verbosity.info.isApplicable() {
            print(item)
        }
    }
    
    static func err(_ item: Any) {
        if Verbosity.error.isApplicable() {
            print(item)
        }
    }
    
    static func warn(_ item: Any) {
        if Verbosity.warning.isApplicable() {
            print(item)
        }
    }
    
    static func perf(_ item: Any) {
        if Verbosity.performance.isApplicable() {
            print(item)
        }
    }
    
}
