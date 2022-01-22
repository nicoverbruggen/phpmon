//
//  ComposerJson.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ComposerJson: Decodable {
    let dependencies: Dictionary<String, String>?
    let devDependencies: Dictionary<String, String>?
    let configuration: Config?
    
    public func getPhpVersion() -> (String, String) {
        // Check if in platform
        if configuration?.platform?.php != nil {
            return (configuration!.platform!.php!, "platform")
        }
        
        // Check if in dependencies
        if dependencies?["php"] != nil {
            return (dependencies!["php"]!, "dependency list")
        }
        
        // Unknown!
        return ("", "unknown")
    }
    
    public func getNotableDependencies() -> [String: String] {
        var notable: [String: String] = [:]
        let scan = ["php", "laravel/framework"]
        
        scan.forEach { dependency in
            if dependencies?[dependency] != nil {
                notable[dependency] = dependencies![dependency]
            }
        }

        return notable
    }
    
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
}


