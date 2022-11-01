//
//  InternalSwitcher.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class InternalSwitcher: PhpSwitcher {

    /**
     Switching to a new PHP version involves:
     - unlinking the current version
     - stopping the active services
     - linking the new desired version
     
     Please note that depending on which version is installed,
     the version that is switched to may or may not be identical to `php`
     (without @version).

     TODO: Use `async` and use structured concurrency: https://www.hackingwithswift.com/swift/5.5/structured-concurrency
     */
    func performSwitch(to version: String, completion: @escaping () -> Void) {
        Log.info("Switching to \(version), unlinking all versions...")

        let versions = getVersionsToBeHandled(version)
        let group = DispatchGroup()

        PhpEnv.shared.availablePhpVersions.forEach { (available) in
            group.enter()

            Task {
                await self.disableDefaultPhpFpmPool(available)
                await self.stopPhpVersion(available)
                group.leave()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            Task {
                Log.info("All versions have been unlinked!")
                Log.info("Linking the new version!")

                for formula in versions {
                    await self.startPhpVersion(formula, primary: (version == formula))
                }

                Log.info("Restarting nginx, just to be sure!")
                await brew("services restart nginx", sudo: true)

                Log.info("The new version(s) have been linked!")
                completion()
            }
        }
    }

    func getVersionsToBeHandled(_ primary: String) -> Set<String> {
        let isolated = Valet.shared.sites.filter { site in
            site.isolatedPhpVersion != nil
        }.map { site in
            return site.isolatedPhpVersion!.versionNumber.short
        }

        var versions: Set<String> = [primary]

        if Valet.enabled(feature: .isolatedSites) {
            versions = versions.union(isolated)
        }

        return versions
    }

    func requiresDisablingOfDefaultPhpFpmPool(_ version: String) -> Bool {
        let pool = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"
        return FileSystem.fileExists(pool)
    }

    func disableDefaultPhpFpmPool(_ version: String) async {
        let pool = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"
        if FileSystem.fileExists(pool) {
            Log.info("A default `www.conf` file was found in the php-fpm.d directory for PHP \(version).")
            let existing = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"
            let new = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf.disabled-by-phpmon"
            do {
                if FileSystem.fileExists(new) {
                    Log.info("A moved `www.conf.disabled-by-phpmon` file was found for PHP \(version), "
                             + "cleaning up so the newer `www.conf` can be moved again.")
                    try FileSystem.remove(new)
                }
                try FileSystem.move(from: existing, to: new)
                Log.info("Success: A default `www.conf` file was disabled for PHP \(version).")
            } catch {
                Log.err(error)
            }
        }
    }

    func stopPhpVersion(_ version: String) async {
        let formula = (version == PhpEnv.brewPhpAlias) ? "php" : "php@\(version)"
        await brew("unlink \(formula)")
        await brew("services stop \(formula)", sudo: true)
        Log.info("Unlinked and stopped services for \(formula)")
    }

    func startPhpVersion(_ version: String, primary: Bool) async {
        let formula = (version == PhpEnv.brewPhpAlias) ? "php" : "php@\(version)"

        if primary {
            Log.info("\(formula) is the primary formula, linking and starting services...")
            await brew("link \(formula) --overwrite --force")
        } else {
            Log.info("\(formula) is an isolated PHP version, starting services only...")
        }

        await brew("services start \(formula)", sudo: true)

        if Valet.enabled(feature: .isolatedSites) && primary {
            let socketVersion = version.replacingOccurrences(of: ".", with: "")
            await Shell.quiet("ln -sF ~/.config/valet/valet\(socketVersion).sock ~/.config/valet/valet.sock")
            Log.info("Symlinked new socket version (valet\(socketVersion).sock → valet.sock).")
        }

    }

}
