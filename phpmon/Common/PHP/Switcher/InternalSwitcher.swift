//
//  InternalSwitcher.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
     */
    func performSwitch(to version: String, completion: @escaping () -> Void) {
        Log.info("Switching to \(version), unlinking all versions...")

        let isolated = Valet.shared.sites.filter { site in
            site.isolatedPhpVersion != nil
        }.map { site in
            return site.isolatedPhpVersion!.versionNumber.homebrewVersion
        }

        var versions: Set<String> = [version]

        if Valet.enabled(feature: .isolatedSites) {
            versions = versions.union(isolated)
        }

        let group = DispatchGroup()

        PhpEnv.shared.availablePhpVersions.forEach { (available) in
            group.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                self.disableDefaultPhpFpmPool(available)
                self.stopPhpVersion(available)
                group.leave()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            Log.info("All versions have been unlinked!")
            Log.info("Linking the new version!")

            for formula in versions {
                self.startPhpVersion(formula, primary: (version == formula))
            }

            Log.info("Restarting nginx, just to be sure!")
            brew("services restart nginx", sudo: true)

            Log.info("The new version(s) have been linked!")
            completion()
        }
    }

    private func disableDefaultPhpFpmPool(_ version: String) {
        let pool = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"
        if FileManager.default.fileExists(atPath: pool) {
            Log.info("A default `www.conf` file was found in the php-fpm.d directory for PHP \(version).")
            let existing = URL(string: "file://\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf")!
            let new = URL(string: "file://\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf.disabled-by-phpmon")!
            do {
                if FileManager.default.fileExists(atPath: new.path) {
                    Log.info("A moved `www.conf.disabled-by-phpmon` file was found for PHP \(version), "
                             + "cleaning up so the newer `www.conf` can be moved again.")
                    try FileManager.default.removeItem(at: new)
                }
                try FileManager.default.moveItem(at: existing, to: new)
                Log.info("Success: A default `www.conf` file was disabled for PHP \(version).")
            } catch {
                Log.err(error)
            }
        }
    }

    private func stopPhpVersion(_ version: String) {
        let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"
        brew("unlink \(formula)")
        brew("services stop \(formula)", sudo: true)
        Log.info("Unlinked and stopped services for \(formula)")
    }

    private func startPhpVersion(_ version: String, primary: Bool) {
        let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"

        if primary {
            Log.info("\(formula) is the primary formula, linking and starting services...")
            brew("link \(formula) --overwrite --force")
        } else {
            Log.info("\(formula) is an isolated PHP version, starting services only...")
        }

        brew("services start \(formula)", sudo: true)

        if Valet.enabled(feature: .isolatedSites) && primary {
            let socketVersion = version.replacingOccurrences(of: ".", with: "")
            Shell.run("ln -sF ~/.config/valet/valet\(socketVersion).sock ~/.config/valet/valet.sock")
            Log.info("Symlinked new socket version (valet\(socketVersion).sock → valet.sock).")
        }

    }

}
