//
//  HomebrewService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/01/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

final class HomebrewService: Sendable, Decodable {
    let name: String
    let service_name: String
    let running: Bool
    let loaded: Bool
    let pid: Int?
    let user: String?
    let status: String?
    let log_path: String?
    let error_log_path: String?

    init(
        name: String,
        service_name: String,
        running: Bool,
        loaded: Bool,
        pid: Int? = nil,
        user: String? = nil,
        status: String? = nil,
        log_path: String? = nil,
        error_log_path: String? = nil
    ) {
        self.name = name
        self.service_name = service_name
        self.running = running
        self.loaded = loaded
        self.pid = pid
        self.user = user
        self.status = status
        self.log_path = log_path
        self.error_log_path = error_log_path
    }

    /**
     Dummy data for preview purposes.
     */
    public static func dummy(named service: String, enabled: Bool, status: String? = nil) -> HomebrewService {
        return HomebrewService(
            name: service,
            service_name: service,
            running: enabled,
            loaded: enabled,
            pid: nil,
            user: nil,
            status: status,
            log_path: nil,
            error_log_path: nil
        )
    }
}
