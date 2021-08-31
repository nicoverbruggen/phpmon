//
//  HomebrewPackage.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewPackage : Decodable {
    
    let name: String
    let full_name: String
    let aliases: [String]
    
    public var version: String {
        return aliases.first!.replacingOccurrences(of: "php@", with: "")
    }
    
}
