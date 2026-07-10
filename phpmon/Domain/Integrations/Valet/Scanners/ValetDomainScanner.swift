//
//  ValetDomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetDomainScanner: DomainScanner {

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Sites

    func resolveSiteCount(paths: [String]) async -> Int {
        // The directory listing and per-entry checks are blocking filesystem
        // work, so they run on the concurrent pool.
        return await offMain { [container] in
            paths.map { path in
                do {
                    let entries = try container.filesystem
                        .getShallowContentsOfDirectory(path)

                    return entries
                        .map { Self.isSite(container, $0, forPath: path) }
                        .filter { $0 == true }
                        .count
                } catch {
                    Log.err("Unexpected error getting contents of \(path): \(error).")
                    return 0
                }

            }.reduce(0, +)
        }
    }

    func resolveSitesFrom(paths: [String]) async -> [ValetSite] {
        // List all candidate site paths off-main first (blocking I/O)...
        let candidates: [String] = await offMain { [container] in
            paths.flatMap { path -> [String] in
                do {
                    return try container.filesystem
                        .getShallowContentsOfDirectory(path)
                        .map { "\(path)/\($0)" }
                } catch {
                    Log.err("Unexpected error getting contents of \(path): \(error).")
                    return []
                }
            }
        }

        // ...then build the main-actor site models from those paths.
        var sites: [ValetSite] = []

        for candidate in candidates {
            if let site = await self.resolveSite(path: candidate) {
                sites.append(site)
            }
        }

        return sites
    }

    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored, and the site is added to Valet's list of sites.
     */
    func resolveSite(path: String) async -> ValetSite? {
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

        let site: ValetSite? = {
            if container.filesystem.isSymlink(path) {
                return ValetSite(container, aliasPath: path, tld: tld, makeDeterminations: false)
            } else if container.filesystem.isDirectory(path) {
                return ValetSite(container, absolutePath: path, tld: tld, makeDeterminations: false)
            }

            return nil
        }()

        // The determinations run separately so the blocking certificate read
        // can hop off the main actor.
        await site?.determine()

        return site
    }

    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored. Returns true if the path can be parsed.
     */
    private nonisolated static func isSite(_ container: Container, _ entry: String, forPath path: String) -> Bool {
        let siteDir = path + "/" + entry

        return (container.filesystem.isDirectory(siteDir) || container.filesystem.isSymlink(siteDir))
    }

    // MARK: - Proxies

    func resolveProxies(directoryPath: String) async -> [ValetProxy] {
        // The directory listing and the per-file reads are blocking I/O, so they
        // run on the concurrent pool; the main actor only parses the contents.
        let files: [(path: String, contents: String)]? = await offMain { [container] in
            guard let entries = try? FileManager
                .default
                .contentsOfDirectory(atPath: directoryPath) else {
                return nil
            }

            return entries
                .filter { !$0.starts(with: ".") }
                .compactMap { entry in
                    let path = "\(directoryPath)/\(entry)"

                    guard let contents = try? container.filesystem.getStringFromFile(path) else {
                        Log.warn("Could not read the nginx configuration file at: `\(path)`")
                        return nil
                    }

                    return (path: path, contents: contents)
                }
        }

        guard let files else {
            Log.err("Could not read Nginx directory at \(directoryPath).")
            return []
        }

        var proxies: [ValetProxy] = []

        for file in files {
            let configuration = NginxConfigurationFile(path: file.path, contents: file.contents)

            guard let proxy = ValetProxy(container, configuration, makeDeterminations: false) else {
                continue
            }

            // The determinations run separately so the blocking certificate read
            // can hop off the main actor.
            await proxy.determine()
            proxies.append(proxy)
        }

        return proxies
    }
}
