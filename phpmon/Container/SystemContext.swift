//
//  SystemContext.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct SystemContext {
    // MARK: - Architecture

    /** The system architecture. Paths differ based on this value. */
    var architecture: String {
        if let override = architectureOverride { return override }

        var systeminfo = utsname()
        uname(&systeminfo)
        let machine = withUnsafeBytes(of: &systeminfo.machine) { bufPtr -> String in
            let data = Data(bufPtr)
            if let lastIndex = data.lastIndex(where: {$0 != 0}) {
                return String(data: data[0...lastIndex], encoding: .isoLatin1)!
            } else {
                return String(data: data, encoding: .isoLatin1)!
            }
        }
        return machine
    }

    // MARK: - Shell

    struct Shell {
        /** The shell path as configured on the system (may be invalid). */
        var configured: String

        /** The validated, working shell path (falls back to `/bin/zsh`). */
        var resolved: String

        /** Whether the configured shell is valid and matches the resolved shell. */
        var isValid: Bool { configured == resolved }
    }

    /** The user's shell information, resolved from the system or overridden for tests. */
    var shell: Shell {
        let configured = configuredShellOverride ?? configured_shell()
        return Shell(
            configured: configured,
            resolved: validated_shell_path(configured)
        )
    }

    // MARK: - Overrides (for testing)

    var architectureOverride: String?
    var configuredShellOverride: String?
}
