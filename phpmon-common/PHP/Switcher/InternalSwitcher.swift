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
        
        let group = DispatchGroup()
        
        PhpEnv.shared.availablePhpVersions.forEach { (available) in
            group.enter()
            
            DispatchQueue.global(qos: .userInitiated).async {
                let formula = (available == PhpEnv.brewPhpVersion)
                ? "php" : "php@\(available)"
                
                brew("unlink \(formula)")
                brew("services stop \(formula)", sudo: true)
                
                Log.perf("Unlinked and stopped services for \(formula)")
                
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            Log.info("All versions have been unlinked!")
            Log.info("Linking the new version!")
            
            let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"
            brew("link \(formula) --overwrite --force")
            brew("services start \(formula)", sudo: true)
            
            Log.info("The new version has been linked!")
            completion()
        }
    }
    
}
