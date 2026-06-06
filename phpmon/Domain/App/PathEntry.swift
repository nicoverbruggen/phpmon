//
//  PathEntry.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct PathEntry {
    /**
     Normalizes a PATH entry so equivalent shell spellings compare the same.

     Supported normalization rules:
     - `~` and `$HOME` both become the resolved home directory
     - `~/...` and `$HOME/...` become absolute paths under the home directory
     - trailing slashes are removed for non-root paths

     This keeps onboarding checks and `.zshrc` writes idempotent even when a user
     already configured the same path using a different home-directory shorthand.
     */
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
