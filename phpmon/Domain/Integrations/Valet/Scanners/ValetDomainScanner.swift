//
//  ValetDomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import ContainerMacro

@ContainerAccess
class ValetDomainScanner: DomainScanner {

    // MARK: - Sites

    func resolveSiteCount(paths: [String]) -> Int {
        return paths.map { path in
            do {
                let entries = try container.filesystem
                    .getShallowContentsOfDirectory(path)

                return entries
                    .map { self.isSite($0, forPath: path) }
                    .filter { $0 == true}
                    .count
            } catch {
                Log.err("Unexpected error getting contents of \(path): \(error).")
                return 0
            }

        }.reduce(0, +)
    }

    func resolveSitesFrom(paths: [String]) -> [ValetSite] {
        var sites: [ValetSite] = []

        paths.forEach { path in
            do {
                let entries = try container.filesystem
                    .getShallowContentsOfDirectory(path)

                return entries.forEach {
                    if let site = self.resolveSite(path: "\(path)/\($0)") {
                        sites.append(site)
                    }
                }
            } catch {
                Log.err("Unexpected error getting contents of \(path): \(error).")
            }
        }

        return sites
    }

    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored, and the site is added to Valet's list of sites.
     */
    func resolveSite(path: String) -> ValetSite? {
        // Get the TLD from the global Valet object
        let tld = Valet.shared.config.tld

        if !container.filesystem.anyExists(path) {
            Log.warn("Could not parse the site: \(path), skipping!")
        }

        // We should also check that we can interpret the path correctly
        if URL(fileURLWithPath: path).lastPathComponent == "" {
            Log.warn("Could not parse the site: \(path), skipping!")
            return nil
        }

        if container.filesystem.isSymlink(path) {
            return ValetSite(container, aliasPath: path, tld: tld)
        } else if container.filesystem.isDirectory(path) {
            return ValetSite(container, absolutePath: path, tld: tld)
        }

        return nil
    }

    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored. Returns true if the path can be parsed.
     */
    private func isSite(_ entry: String, forPath path: String) -> Bool {
        let siteDir = path + "/" + entry

        return (container.filesystem.isDirectory(siteDir) || container.filesystem.isSymlink(siteDir))
    }

    // MARK: - Proxies

    func resolveProxies(directoryPath: String) -> [ValetProxy] {
        return try! FileManager
            .default
            .contentsOfDirectory(atPath: directoryPath)
            .filter {
                return !$0.starts(with: ".")
            }
            .compactMap {
                return NginxConfigurationFile.from(container, filePath: "\(directoryPath)/\($0)")
            }
            .filter {
                return $0.proxy != nil
            }
            .map {
                return ValetProxy(container, $0)
            }
    }
}
