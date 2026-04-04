//
//  ValetScannerTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/03/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct ValetDomainScannerTest {
    private var container: Container
    private var scanner: ValetDomainScanner

    init() throws {
        container = Container.fake(files: [
            "/Users/user/.config/valet/Sites/valid-link":
                .fake(.symlink, "/Users/user/Code/valid-project"),
            "/Users/user/.config/valet/Sites/broken-link":
                .fake(.symlink, "/Users/user/Code/deleted-project"),
            "/Users/user/Code/valid-project":
                .fake(.directory),
            "/Users/user/Sites/parked-site":
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

        scanner = ValetDomainScanner(container)

        // Set up the global Valet config so resolveSite can access `Valet.shared.config.tld`
        Valet.shared.config = try JSONDecoder().decode(
            Valet.Configuration.self,
            from: Data("{\"tld\": \"test\", \"paths\": [], \"loopback\": \"127.0.0.1\"}".utf8)
        )
    }

    @Test func resolving_broken_symlink_does_not_crash() {
        // This symlink exists but points to a target that doesn't exist in the filesystem.
        // Previously, this would crash due to `try!` in ValetSite.init(aliasPath:).
        let site = scanner.resolveSite(path: "/Users/user/.config/valet/Sites/broken-link")

        #expect(site == nil)
    }

    @Test func resolving_valid_symlink_returns_site() {
        let site = scanner.resolveSite(path: "/Users/user/.config/valet/Sites/valid-link")

        #expect(site != nil)
        #expect(site?.name == "valid-link")
        #expect(site?.absolutePath == "/Users/user/Code/valid-project")
    }

    @Test func resolving_parked_directory_returns_site() {
        let site = scanner.resolveSite(path: "/Users/user/Sites/parked-site")

        #expect(site != nil)
        #expect(site?.name == "parked-site")
    }

    @Test func resolving_sites_with_broken_symlink_skips_it() {
        // When scanning all paths, a broken symlink should be skipped
        // without crashing, and valid sites should still be returned.
        let sites = scanner.resolveSitesFrom(paths: [
            "/Users/user/.config/valet/Sites",
            "/Users/user/Sites"
        ])

        let names = sites.map { $0.name }.sorted()

        #expect(!names.contains("broken-link"))
        #expect(names.contains("valid-link"))
        #expect(names.contains("parked-site"))
    }
}
