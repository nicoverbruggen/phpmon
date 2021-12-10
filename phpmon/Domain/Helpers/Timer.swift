//
//  BenchmarkTimer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class BenchmarkTimer {
    let startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()

        return duration!
    }

    var duration: CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}
