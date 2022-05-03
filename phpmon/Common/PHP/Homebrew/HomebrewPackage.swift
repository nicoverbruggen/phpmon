//
//  HomebrewPackage.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewPackage: Decodable {

    let name: String
    let full_name: String
    let aliases: [String]
    let installed: [HomebrewInstalled]
    let linked_keg: String?

    public var version: String {
        return aliases.first!
            .replacingOccurrences(of: "php@", with: "")
    }

}

struct HomebrewInstalled: Decodable {
    let version: String
    let built_as_bottle: Bool
    let installed_as_dependency: Bool
    let installed_on_request: Bool
}
