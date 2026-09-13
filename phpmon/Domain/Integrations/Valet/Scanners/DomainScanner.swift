//
//  DomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// The scanning methods are `async` so implementations can run the blocking
// filesystem work (directory listings, certificate reads) off the main actor,
// while still building the main-actor `ValetSite`/`ValetProxy` models on it.
protocol DomainScanner {

    // MARK: - Sites

    func resolveSiteCount(paths: [String]) async -> Int

    func resolveSitesFrom(paths: [String]) async -> [ValetSite]

    func resolveSite(path: String) async -> ValetSite?

    // MARK: - Proxies

    func resolveProxies(directoryPath: String) async -> [ValetProxy]

}
