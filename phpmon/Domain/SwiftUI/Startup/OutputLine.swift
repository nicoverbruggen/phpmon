//
//  OutputLine.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct OutputLine: Identifiable {
    let id = UUID()
    let text: String
    let stream: ShellStream
}

/**
 Convenience helpers for OutputLine.
 */
extension OutputLine {
    static func make(
        _ text: [String],
        as stream: ShellStream = .stdOut
    ) -> [OutputLine] {
        return text.map {
            OutputLine(text: $0, stream: stream)
        }
    }

    static func outLines( _ text: [String]) -> [OutputLine] {
        Self.make(text, as: .stdOut)
    }

    static func errLines( _ text: [String]) -> [OutputLine] {
        Self.make(text, as: .stdErr)
    }
}
