//
//  BrewDiagnosticsConcurrencyTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

/// Exercises concurrent tap reloads and array reads. Thread Sanitizer checks
/// the accesses while the final assertion checks the loaded data.
@Suite(.serialized)
struct BrewDiagnosticsConcurrencyTest {
    let diagnostics: BrewDiagnostics

    init() {
        let container = Container.fake(shell: [
            "/opt/homebrew/bin/brew tap": .delayed(0.005, """
            homebrew/core
            homebrew/cask
            shivammathur/php
            nicoverbruggen/cask
            """),
            "/usr/local/bin/brew tap": .delayed(0.005, """
            homebrew/core
            homebrew/cask
            shivammathur/php
            nicoverbruggen/cask
            """)
        ])

        diagnostics = BrewDiagnostics(container)
    }

    @Test func concurrent_loadInstalledTaps_and_reads_do_not_corrupt() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<40 {
                group.addTask { await diagnostics.loadInstalledTaps() }
            }
            for _ in 0..<400 {
                group.addTask {
                    // Iterate the array elements while it is being reassigned off-main.
                    _ = diagnostics.installedTaps.reduce(into: "") { $0 += $1 }
                }
            }
            await group.waitForAll()
        }

        #expect(diagnostics.installedTaps == [
            "homebrew/core", "homebrew/cask", "shivammathur/php", "nicoverbruggen/cask"
        ])
    }
}
