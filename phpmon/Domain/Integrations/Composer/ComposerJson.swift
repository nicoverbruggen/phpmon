//
//  ComposerJson.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 This `Decodable` class is used to directly map `composer.json`
 to this object.
 */
struct ComposerJson: Decodable {
    
    // MARK: - JSON structure
    
    let dependencies: Dictionary<String, String>?
    let devDependencies: Dictionary<String, String>?
    let configuration: Config?
    
    private enum CodingKeys: String, CodingKey {
        case dependencies = "require"
        case devDependencies = "require-dev"
        case configuration = "config"
    }
    
    struct Config: Decodable {
        let platform: Platform?
    }
    
    struct Platform: Decodable {
        let php: String?
    }
    
    // MARK: - Helpers
    
    /**
     Checks what the PHP version constraint is.
     Returns a tuple (constraint, location of constraint).
     */
    public func getPhpVersion() -> (String, ValetSite.VersionSource)
    {
        // Check if in platform
        if configuration?.platform?.php != nil {
            return (configuration!.platform!.php!, .platform)
        }
        
        // Check if in dependencies
        if dependencies?["php"] != nil {
            return (dependencies!["php"]!, .require)
        }
        
        // Unknown!
        return ("???", .unknown)
    }
    
    /**
     Checks if any notable dependencies can be resolved.
     Only notable dependencies are saved.
     */
    public func getNotableDependencies() -> [String: String] {
        var notable: [String: String] = [:]
        
        var scan = Array(PhpFrameworks.DependencyList.keys)
        scan.append("php")
        
        scan.forEach { dependency in
            if dependencies?[dependency] != nil {
                notable[dependency] = dependencies![dependency]
            }
        }

        return notable
    }
    
}


