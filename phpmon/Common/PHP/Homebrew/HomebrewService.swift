//
//  HomebrewService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewService: Decodable, Equatable, Hashable {
    let name: String
    let service_name: String
    let running: Bool
    let loaded: Bool
    let pid: Int?
    let user: String?
    let status: String?
    let log_path: String?
    let error_log_path: String?

    /**
     Dummy data for preview purposes.
     */
    public static func dummy(named service: String, enabled: Bool) -> Self {
        return HomebrewService(
            name: service,
            service_name: service,
            running: enabled,
            loaded: enabled,
            pid: nil,
            user: nil,
            status: nil,
            log_path: nil,
            error_log_path: nil
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(service_name)
        hasher.combine(pid)
    }
}
