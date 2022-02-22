//
//  Valet.Configuration.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Valet {
    
    struct Configuration: Decodable {
        /// Top level domain suffix. Usually "test" but can be set to something else.
        /// - Important: Does not include the actual dot. ("test", not ".test"!)
        let tld: String
        
        /// The paths that need to be checked.
        let paths: [String]
        
        /// The loopback address. Optional.
        let loopback: String?
        
        /// The default site that is served if the domain is not found. Optional.
        let defaultSite: String?
        
        private enum CodingKeys: String, CodingKey {
            case tld, paths, loopback, defaultSite = "default"
        }
    }
    
}
