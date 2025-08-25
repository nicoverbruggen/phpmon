//
//  PackagistP2Response.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

struct PackagistP2Response: Codable {
    let packages: [String: [PackageInfo]]
}

struct PackageInfo: Codable {
    let version: String?
    let version_normalized: String?
}
