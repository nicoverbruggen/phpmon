//
//  HomebrewDecodable.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewVersion: Decodable {
    let stable: String
    let head: String?
    let bottle: Bool?
}

struct HomebrewPackage: Decodable {
    let full_name: String
    let aliases: [String]
    let installed: [HomebrewInstalled]
    let versions: HomebrewVersion?
    let linked_keg: String?

    public var version: String? {
        // Get the stable version directly
        if let versions, let version = try? VersionNumber.parse(versions.stable).short {
            return version
        }

        // Read it from the aliases list
        if !aliases.isEmpty {
            return aliases.first!.replacing("php@", with: "")
        }

        // Fallback to the linked keg
        if let linked = linked_keg,
           let version = try? VersionNumber.parse(linked).short {
            return version
        }

        fatalError("Could not determine package")
    }
}

struct HomebrewInstalled: Decodable {
    let version: String
    let built_as_bottle: Bool
    let installed_as_dependency: Bool
    let installed_on_request: Bool
}

struct OutdatedFormulae: Decodable {
    let formulae: [OutdatedFormula]
}

struct OutdatedFormula: Decodable {
    let name: String
    let installed_versions: [String]
    let current_version: String
    let pinned: Bool
    let pinned_version: String?
}
