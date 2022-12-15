//
//  DomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol DomainScanner {

    // MARK: - Sites

    func resolveSiteCount(paths: [String]) -> Int

    func resolveSitesFrom(paths: [String]) -> [ValetSite]

    func resolveSite(path: String) -> ValetSite?

    // MARK: - Proxies

    func resolveProxies(directoryPath: String) -> [ValetProxy]

}
