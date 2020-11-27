//
//  HomebrewPackage.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/11/2020.
//  Copyright © 2020 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewPackage : Decodable {
    let name: String
    let full_name: String
    let aliases: [String]
    
    public func getVersion() -> String {
        return aliases.first!.replacingOccurrences(of: "php@", with: "")
    }
}
