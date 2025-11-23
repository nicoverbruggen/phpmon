//
//  Measurements.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

public struct Measurement {
    let started = Date()

    var milliseconds: Double {
        return round(Date().timeIntervalSince(started) * 1000 * 1000) / 1000
    }
}
