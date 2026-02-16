//
//  URLReachable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestURL {
    static func isReachable(url: String) -> Bool {
        let process = Process()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = [
            "-s", "-o", "/dev/null",
            "--max-time", "3",
            url
        ]

        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
