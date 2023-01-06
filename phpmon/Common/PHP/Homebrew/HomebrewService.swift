//
//  HomebrewService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class HomebrewService: Decodable, Equatable, Hashable {
    let name: String
    let service_name: String
    var running: Bool
    var loaded: Bool
    var pid: Int?
    var user: String?
    var status: String?
    var log_path: String?
    var error_log_path: String?

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
    public static func dummy(named service: String, enabled: Bool) -> HomebrewService {
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
        hasher.combine(status)
    }

    static func == (lhs: HomebrewService, rhs: HomebrewService) -> Bool {
        return lhs.name == rhs.name
        && lhs.service_name == rhs.service_name
        && lhs.pid == rhs.pid
        && lhs.status == rhs.status
    }
}
