//
//  BrewDiagnosticsConcurrencyTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

///
/// `BrewDiagnostics.installedTaps` / `.trustedTaps` are plain `var` arrays on a shared
/// singleton, reassigned inside `loadInstalledTaps()` / `loadTrustedTaps()` (both
/// `async`, off the main thread) and read (unsynchronized) from several async contexts
/// — the same shape as the `Valet.sites` crash. `loadInstalledTaps()` is invoked from
/// multiple independent triggers (the PHP Version Manager UI, warning evaluations,
/// startup), so two flows can overlap.
///
/// This test hammers `loadInstalledTaps()` concurrently with element-iterating reads of
/// `installedTaps`.
///
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

        App.shared.container = container
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

        // No corrupted/garbage entries, whether the array ended up populated or empty.
        #expect(diagnostics.installedTaps.allSatisfy { !$0.isEmpty })
    }
}
