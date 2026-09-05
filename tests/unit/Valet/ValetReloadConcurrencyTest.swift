//
//  ValetReloadConcurrencyTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

///
/// Regression coverage for the 26.05.3 crashes.
///
/// `Valet.resolvePaths()` used to mutate `Valet.shared.sites` / `.proxies` **off the
/// main thread** while the UI reads the same arrays **on the main thread**, with no
/// synchronization. Swift arrays are not thread-safe, so this corrupted the array
/// buffer and crashed: the writer trapped in `sites.insert(...)`, and readers
/// segfaulted while iterating the array during a SwiftUI update.
///
/// The fix keeps the blocking scan off the main thread but performs every mutation of
/// `sites`/`proxies`/`isBusy` on the main actor. These tests reproduce the race by
/// hammering `reloadSites()` concurrently with main-actor reads that iterate the array
/// elements (which is what dereferences the element pointers that used to crash). They
/// crash / trip ThreadSanitizer on the pre-fix code and pass cleanly with the fix.
///
/// The suite is `.serialized` because it configures global singletons
/// (`App.shared.container`, `Valet.shared`, `ValetScanner.active`).
///
@Suite(.serialized)
struct ValetReloadConcurrencyTest {
    init() {
        let container = Container.fake(files: [
            "/Users/user/.config/valet/Sites/valid-link":
                .fake(.symlink, "/Users/user/Code/valid-project"),
            "/Users/user/.config/valet/Sites/another-link":
                .fake(.symlink, "/Users/user/Code/another-project"),
            "/Users/user/Code/valid-project":
                .fake(.directory),
            "/Users/user/Code/another-project":
                .fake(.directory),
            "/Users/user/Sites/parked-site":
                .fake(.directory),
            "/Users/user/Sites/second-parked-site":
                .fake(.directory),
            "~/.config/valet/config.json":
                .fake(.text, """
                {
                    "tld": "test",
                    "paths": [
                        "/Users/user/.config/valet/Sites",
                        "/Users/user/Sites"
                    ],
                    "loopback": "127.0.0.1"
                }
                """)
        ])

        App.shared.container = container
        Valet.shared.container = container
        ValetScanner.active = ValetDomainScanner(container)
    }

    /// Sanity check: after the async refactor, `reloadSites()` still populates the
    /// site list correctly.
    @Test func reload_sites_populates_expected_sites() async {
        await Valet.shared.reloadSites()

        let names = await MainActor.run {
            Valet.shared.sites.map { $0.name }.sorted()
        }

        #expect(names.contains("valid-link"))
        #expect(names.contains("parked-site"))
    }

    @Test func overlapping_reload_does_not_replace_configuration_during_a_scan() async throws {
        let previousScanner = ValetScanner.active
        defer { ValetScanner.active = previousScanner }

        ValetScanner.active = ReloadDuringScan {
            try! Valet.shared.container.filesystem.writeAtomicallyToFile(
                "~/.config/valet/config.json",
                content: #"{"tld":"changed","paths":[],"loopback":"127.0.0.1"}"#
            )
            await Valet.shared.reloadSites()
        }

        await Valet.shared.reloadSites()

        #expect(Valet.shared.config.tld == "test")
        #expect(!Valet.shared.isBusy)
    }

    /// Hammers `reloadSites()` (which reassigns and inserts into `sites` off-main on
    /// the pre-fix code) while readers **iterate the array elements** on the main
    /// actor — touching `name`/`absolutePath` on each element, exactly the access
    /// pattern that segfaulted during SwiftUI diffing. Must complete cleanly and leave
    /// the site list consistent.
    @Test func concurrent_reloads_and_element_reads_do_not_corrupt_sites() async {
        // Prime the list so readers have elements to walk from the first iteration.
        await Valet.shared.reloadSites()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<40 {
                group.addTask { await Valet.shared.reloadSites() }
            }
            for _ in 0..<400 {
                group.addTask {
                    _ = await MainActor.run {
                        // Walk every element and read its stored properties. On the
                        // pre-fix code this dereferences pointers in a buffer being
                        // mutated off-main -> corruption / trap.
                        Valet.shared.sites.reduce(into: "") { acc, site in
                            acc += site.name + site.absolutePath
                        }
                    }
                }
            }
            await group.waitForAll()
        }

        let names = await MainActor.run {
            Valet.shared.sites.map { $0.name }.sorted()
        }

        #expect(names.contains("valid-link"))
        #expect(names.contains("parked-site"))
    }

    /// Exercises the exact production reader — `Valet.getDomainListable()` returns
    /// `sites + proxies`, concatenating and iterating both arrays (this is
    /// `Valet.swift`'s `getDomainListable()`, read by the domain-list UI on the main
    /// thread) — concurrently with reloads.
    @Test func concurrent_reloads_and_domain_listable_reads_are_safe() async {
        await Valet.shared.reloadSites()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<40 {
                group.addTask { await Valet.shared.reloadSites() }
            }
            for _ in 0..<400 {
                group.addTask {
                    _ = await MainActor.run {
                        Valet.getDomainListable().map { $0.getListableName() }
                    }
                }
            }
            await group.waitForAll()
        }

        let count = await MainActor.run { Valet.getDomainListable().count }
        #expect(count >= 2)
    }
}

private struct ReloadDuringScan: DomainScanner {
    let onScan: () async -> Void

    func resolveSiteCount(paths: [String]) async -> Int { 0 }
    func resolveSite(path: String) async -> ValetSite? { nil }
    func resolveProxies(directoryPath: String) async -> [ValetProxy] { [] }

    func resolveSitesFrom(paths: [String]) async -> [ValetSite] {
        await onScan()
        return []
    }
}
