//
//  DetectableService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct DetectableService: Hashable {
    let binary: String
    let service: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(service)
    }
}
