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
    
    public static func loadAll(
        filter: [String] = [PhpEnv.phpInstall.formula, "nginx", "dnsmasq"],
        completion: @escaping ([HomebrewService]) -> Void
    ) {
        DispatchQueue.global(qos: .background).async {
            let data = Shell
                .pipe("sudo \(Paths.brew) services info --all --json", requiresPath: true)
                .data(using: .utf8)!
            
            let services = try! JSONDecoder()
                .decode([HomebrewService].self, from: data)
                .filter({ return filter.contains($0.name) })
            
            completion(services)
        }
    }
}
