//
//  HomebrewService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewService: Decodable, Equatable {
    let name: String
    let service_name: String
    let running: Bool
    let loaded: Bool
    let pid: Int?
    let user: String?
    let status: String?
    let log_path: String?
    let error_log_path: String?
    
    public static let serviceToCheck = "nginx"
    public static func servicesCanBeLoaded() -> Bool {
        let serviceInfo = try? JSONDecoder().decode(
            [HomebrewService].self,
            from: Shell.pipe(
                "sudo \(Paths.brew) services info \(self.serviceToCheck) --json",
                requiresPath: true
            ).data(using: .utf8)!
        )
        
        return serviceInfo != nil
    }
}
