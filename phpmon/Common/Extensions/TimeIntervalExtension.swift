//
//  TimeExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// Pure value-type math — nonisolated so it can be used from any isolation (e.g. as a
// default value for the nonisolated `Constants`, or from actor/off-main code).
extension TimeInterval {
    nonisolated static func milliseconds(_ value: Double) -> TimeInterval { value / 1000 }
    nonisolated static func seconds(_ value: Double) -> TimeInterval { value }
    nonisolated static func minutes(_ value: Double) -> TimeInterval { value * 60 }
    nonisolated static func hours(_ value: Double) -> TimeInterval { value * 3600 }
    nonisolated static func days(_ value: Double) -> TimeInterval { value * 86400 }

    nonisolated var nanoseconds: UInt64 {
        return UInt64(self * 1_000_000_000)
    }
}

extension Date {
    nonisolated func adding(_ interval: TimeInterval) -> Date {
        return self.addingTimeInterval(interval)
    }
}
