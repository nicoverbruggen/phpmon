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
    func performSwitch(to version: String, completion: @escaping () -> Void)
    {
        Log.info("Switching to \(version), unlinking all versions...")
        
        let isolated = Valet.shared.sites.filter { site in
            site.isolatedPhpVersion != nil
        }.map { site in
            return site.isolatedPhpVersion!.versionNumber.homebrewVersion
        }
        
        var versions: Set<String> = []
        // TODO: Do not use isolation if on Valet 2.x
        versions = versions.union(isolated)
        versions = versions.union([version])
        
        let group = DispatchGroup()
        
        PhpEnv.shared.availablePhpVersions.forEach { (available) in
            group.enter()
            
            DispatchQueue.global(qos: .userInitiated).async {
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
            
            Log.info("The new version(s) has been linked!")
            completion()
        }
    }
    
    private func stopPhpVersion(_ version: String) {
        let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"
        brew("unlink \(formula)")
        brew("services stop \(formula)", sudo: true)
        Log.perf("Unlinked and stopped services for \(formula)")
    }
    
    private func startPhpVersion(_ version: String, primary: Bool) {
        let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"
        
        if (primary) {
            Log.perf("PHP \(formula) is the primary formula, linking and starting services...")
            brew("link \(formula) --overwrite --force")
        } else {
            Log.perf("PHP \(formula) is an isolated PHP version, starting services only...")
        }
        
        brew("services start \(formula)", sudo: true)
        
        // TODO: Symlink might not need to be created if Valet 2.x
        let socketVersion = version.replacingOccurrences(of: ".", with: "")
        Shell.run("ln -sF ~/.config/valet/valet\(socketVersion).sock ~/.config/valet/valet.sock")
        Log.perf("Symlinked new socket version.")
    }
    
}
