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
        Task { await self.reloadServicesStatus() }
    }

    /**
     This method allows us to reload the Homebrew services, but we run this command
     twice (once for user services, and once for root services). Please note that
     these two commands are executed concurrently.
     */
    override func reloadServicesStatus() async {
        await withTaskGroup(of: [HomebrewService].self, body: { group in
            group.addTask {
                let rootServiceNames = self.formulae
                    .filter { $0.elevated }
                    .map { $0.name }

                let rootJson = await Shell
                    .pipe("sudo \(Paths.brew) services info --all --json")
                    .out.data(using: .utf8)!

                return try! JSONDecoder()
                    .decode([HomebrewService].self, from: rootJson)
                    .filter({ return rootServiceNames.contains($0.name) })
            }

            group.addTask {
                let userServiceNames = self.formulae
                    .filter { !$0.elevated }
                    .map { $0.name }

                let normalJson = await Shell
                    .pipe("\(Paths.brew) services info --all --json")
                    .out.data(using: .utf8)!

                return try! JSONDecoder()
                    .decode([HomebrewService].self, from: normalJson)
                    .filter({ return userServiceNames.contains($0.name) })
            }

            // Ensure both commands complete (but run concurrently)
            for await services in group {
                // For both groups (user and root services), set the service to the wrapper object
                for service in services {
                    self[service.name]?.service = service
                }
            }

            // Ensure that every wrapper is considered no longer busy
            for wrapper in serviceWrappers {
                wrapper.isBusy = false
            }

            // Broadcast that all services have been updated
            self.broadcastServicesUpdated()
        })
    }

    override func toggleService(named: String) async {
        // TODO
    }
}
