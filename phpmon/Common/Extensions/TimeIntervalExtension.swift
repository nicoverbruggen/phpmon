//
//  TimeExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension TimeInterval {
    static func milliseconds(_ value: Double) -> TimeInterval { value / 1000 }
    static func seconds(_ value: Double) -> TimeInterval { value }
    static func minutes(_ value: Double) -> TimeInterval { value * 60 }
    static func hours(_ value: Double) -> TimeInterval { value * 3600 }
    static func days(_ value: Double) -> TimeInterval { value * 86400 }

    var nanoseconds: UInt64 {
        return UInt64(self * 1_000_000_000)
    }
}

extension Date {
    func adding(_ interval: TimeInterval) -> Date {
        return self.addingTimeInterval(interval)
    }
}
