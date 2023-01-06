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

            for await services in group {
                for service in services {
                    guard let wrapper = self[service.name] else {
                        break
                    }

                    wrapper.service = service
                }
            }

            for wrapper in serviceWrappers {
                wrapper.isBusy = false
            }

            self.broadcastServicesUpdated()
        })
    }
}
