//
//  ValetServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetServicesManager: ServicesManager {
    override init() {
        super.init()

        // Load the initial services state
        Task { await self.updateServices() }
    }

    override func updateServices() async {
        // TODO
    }
}

// TODO

/*
public static func loadHomebrewServices() async {
    await Self.shared.updateServicesList()

    Task {
        let rootServiceNames = Self.shared.formulae
            .filter { $0.elevated }
            .map { $0.name }

        let rootJson = await Shell
            .pipe("sudo \(Paths.brew) services info --all --json")
            .out.data(using: .utf8)!

        let rootServices = try! JSONDecoder()
            .decode([HomebrewService].self, from: rootJson)
            .filter({ return rootServiceNames.contains($0.name) })

        Task { @MainActor in
            for service in rootServices {
                Self.shared.services[service.name]!.service = service
            }
        }
    }

    Task {
        let userServiceNames = Self.shared.formulae
            .filter { !$0.elevated }
            .map { $0.name }

        let normalJson = await Shell
            .pipe("\(Paths.brew) services info --all --json")
            .out.data(using: .utf8)!

        let userServices = try! JSONDecoder()
            .decode([HomebrewService].self, from: normalJson)
            .filter({ return userServiceNames.contains($0.name) })

        Task { @MainActor in
            for service in userServices {
                Self.shared.services[service.name]!.service = service
            }
        }
    }
}
*/
