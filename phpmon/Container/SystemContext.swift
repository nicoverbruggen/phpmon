//
//  SystemContext.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct SystemContext {
    init(
        architectureOverride: String? = nil,
        configuredShellOverride: String? = nil
    ) {
        architecture = architectureOverride ?? SystemContext.resolveArchitecture()

        let configuredShell = configuredShellOverride ?? ShellEnvironment.configuredShell()

        shell = Shell(
            configured: configuredShell,
            resolved: ShellEnvironment.validatedShellPath(configuredShell)
        )

        // Do the important system setup checks
        Log.always("PHP Monitor is running with the architecture: \(architecture)")
        Log.always("Using the following resolved shell: \(shell.resolved)")
    }

    // MARK: - Architecture

    /** The system architecture. Paths differ based on this value. */
    let architecture: String

    private static func resolveArchitecture() -> String {
        var systeminfo = utsname()
        uname(&systeminfo)
        return withUnsafeBytes(of: &systeminfo.machine) { bufPtr -> String in
            let data = Data(bufPtr)
            if let lastIndex = data.lastIndex(where: {$0 != 0}) {
                return String(data: data[0...lastIndex], encoding: .isoLatin1)!
            } else {
                return String(data: data, encoding: .isoLatin1)!
            }
        }
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
    let shell: Shell
}
