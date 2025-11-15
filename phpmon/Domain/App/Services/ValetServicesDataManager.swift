//
//  ValetServicesDataManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor ValetServicesDataManager {
    private let container: Container

    init(_ container: Container) {
        self.container = container
    }

    /**
     The last known state of all Homebrew services (via the `formulae` property).
     */
    private(set) var homebrewServices: [HomebrewService] = []

    /**
     All Homebrew formulae that we need to check the status for.

     This will include the Valet-required services (php, nginx, dnsmasq) but depending
     on how the user has configured their setup, this may also include other services
     like databases or such, which may be very helpful.
     */
    var formulae: [HomebrewFormula] {
        let f = HomebrewFormulae(container)

        // We will always include these (required for Valet)
        var formulae = [f.php, f.nginx, f.dnsmasq]

        // We may also load additional formulae based on Preferences
        if let customServices = Preferences.custom.services, !customServices.isEmpty {
            formulae.append(contentsOf: customServices.map { item in
                return HomebrewFormula(item, elevated: false)
            })
        }

        return formulae
    }

    /**
     This method allows us to reload the Homebrew services, but we run this command
     twice (once for user services, and once for root services). Please note that
     these two commands are executed concurrently.

     If this fails, question marks will be displayed in the menu bar and we will
     try one more time to reload the services.
     */
    func reloadServicesStatus(isRetry: Bool) async -> [HomebrewService] {
        if !Valet.installed {
            Log.info("Not reloading services because running in Standalone Mode.")
            return []
        }

        return await withTaskGroup(of: [HomebrewService].self) { group in
            group.addTask {
                await self.fetchHomebrewServices(elevated: true)
            }

            group.addTask {
                await self.fetchHomebrewServices(elevated: false)
            }

            // Collect all services into a local variable (avoids intermediate state)
            var collectedServices: [HomebrewService] = []

            for await services in group {
                collectedServices.append(contentsOf: services)
            }

            // Single atomic update to actor state after all data is collected
            self.homebrewServices = collectedServices

            // Do we need to retry?
            if homebrewServices.isEmpty && !isRetry {
                Log.warn("Failed to retrieve any Homebrew services data. Retrying once in 2 seconds...")
                await delay(seconds: 2)
                return await self.reloadServicesStatus(isRetry: true)
            }

            return homebrewServices
        }
    }

    /**
     Fetches Homebrew services information for either elevated (root) or user services.

     - Parameter elevated: Whether to fetch services running as root (true) or user (false)
     - Returns: Array of HomebrewService objects, or empty array if fetching fails
     */
    private func fetchHomebrewServices(elevated: Bool) async -> [HomebrewService] {
        let serviceNames = self.formulae
            .filter { $0.elevated == elevated }
            .map { $0.name }

        let command = elevated
            ? "sudo \(self.container.paths.brew) services info --all --json"
            : "\(self.container.paths.brew) services info --all --json"

        let output = await self.container.shell.pipe(command).out

        guard let jsonData = output.data(using: .utf8) else {
            Log.err("Failed to convert \(elevated ? "root" : "user") services output to UTF-8 data.")
            return []
        }

        do {
            return try JSONDecoder()
                .decode([HomebrewService].self, from: jsonData)
                .filter { serviceNames.contains($0.name) }
        } catch {
            Log.err("Failed to decode \(elevated ? "root" : "user") services JSON: \(error)")
            return []
        }
    }

    func getHomebrewService(named: String) -> HomebrewService? {
        return homebrewServices.first { $0.name == named }
    }
}
