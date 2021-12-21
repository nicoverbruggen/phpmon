//
//  AliasConflict.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class HomebrewDiagnostics {
    
    enum Errors: String {
        case aliasConflict = "alias_conflict"
    }
    
    static let shared = HomebrewDiagnostics()
    var errors: [HomebrewDiagnostics.Errors] = []

    init() {
        if determineAliasConflicts() {
            errors.append(.aliasConflict)
        }
    }
    
    /**
     It is possible to have the `shivammathur/php` tap installed, and for the core homebrew information to be outdated.
     This will then result in two different aliases claiming to point to the same formula (`php`).
     This will break all linking functionality in PHP Monitor, and the user needs to be informed of this.
     
     This check only needs to be performed if the `shivammathur/php` tap is active.
     */
    public func determineAliasConflicts() -> Bool
    {
        let tapAlias = Shell.pipe("\(Paths.brew) info shivammathur/php/php --json")
        
        if tapAlias.contains("brew tap shivammathur/php") || tapAlias.contains("Error") {
            Log.info("The user does not appear to have tapped: shivammathur/php")
            return false
        } else {
            Log.info("The user DOES have the following tapped: shivammathur/php")
            Log.info("Checking for `php` formula conflicts...")
            
            let tapPhp = try! JSONDecoder().decode(
                [HomebrewPackage].self,
                from: tapAlias.data(using: .utf8)!
            ).first!
            
            if tapPhp.version != PhpSwitcher.brewPhpVersion {
                Log.warn("The `php` formula alias seems to be the different between the tap and core. This could be a problem!")
                Log.info("Determining whether both of these versions are installed...")
                
                let bothInstalled = PhpSwitcher.shared.availablePhpVersions.contains(tapPhp.version)
                    && PhpSwitcher.shared.availablePhpVersions.contains(PhpSwitcher.brewPhpVersion)
                
                if bothInstalled {
                    Log.warn("Both conflicting aliases seem to be installed, warning the user!")
                } else {
                    Log.info("Conflicting aliases are not both installed, seems fine!")
                }
                
                return bothInstalled
            }
            
            Log.info("All seems to be OK. No conflicts, both are PHP \(tapPhp.version).")
            
            return false
        }
    }
}
