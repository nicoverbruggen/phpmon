//
//  PathEntry.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct PathEntry {
    static func normalize(_ path: String, homePath: String) -> String {
        var normalized = path

        if normalized == "~" || normalized == "$HOME" {
            normalized = homePath
        } else if normalized.hasPrefix("~/") {
            normalized = homePath + String(normalized.dropFirst(1))
        } else if normalized.hasPrefix("$HOME/") {
            normalized = homePath + String(normalized.dropFirst("$HOME".count))
        }

        while normalized.count > 1 && normalized.hasSuffix("/") {
            normalized.removeLast()
        }

        return normalized
    }
}
