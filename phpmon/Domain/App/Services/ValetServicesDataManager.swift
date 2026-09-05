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
    private let registry: ServicesRegistry

    init(_ container: Container, registry: ServicesRegistry) {
        self.container = container
        self.registry = registry
    }

    /**
     The last known state of all Homebrew services.
     */
    private(set) var homebrewServices: [HomebrewService] = []

    /**
     Loads root and user services concurrently. Each query includes only installed
     formulae managed by PHP Monitor, including versioned service names.

     If this fails, question marks will be displayed in the menu bar and we will
     try one more time to reload the services.
     */
    func reloadServicesStatus(isRetry: Bool) async -> [HomebrewService] {
        let formulae = await registry.reloadFormulae()

        // `Valet.installed` is main-actor isolated; hop to read it from this actor.
        let valetInstalled = await MainActor.run { Valet.installed }
        if !valetInstalled {
            Log.info("Not reloading services because running in Standalone Mode.")
            return []
        }

        // Refresh on every reload because installations can change after startup.
        // If discovery fails, retain the previous services query with --all.
        let deadline = ProcessInfo.processInfo.systemUptime + .seconds(10)
        let installed = await container.shell.pipe("\(container.paths.brew) list --formula", timeout: .seconds(10))
        let names = installed.out.split(separator: "\n").map(String.init)
        let installedFormulae = installed.err.isEmpty && !names.isEmpty && names.allSatisfy {
            $0.range(of: "^[a-zA-Z0-9][a-zA-Z0-9@+_.-]*$", options: .regularExpression) != nil
        } ? names : nil

        return await withTaskGroup(of: [HomebrewService].self) { group in
            group.addTask {
                await self.fetchHomebrewServices(
                    elevated: true, formulae: formulae, installedFormulae: installedFormulae, deadline: deadline
                )
            }

            group.addTask {
                await self.fetchHomebrewServices(
                    elevated: false, formulae: formulae, installedFormulae: installedFormulae, deadline: deadline
                )
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
    func fetchHomebrewServices(
        elevated: Bool,
        formulae: [HomebrewFormula],
        installedFormulae: [String]?,
        deadline: TimeInterval = ProcessInfo.processInfo.systemUptime + .seconds(10)
    ) async -> [HomebrewService] {
        // Discovery and fallback share one budget, rather than each extending a slow reload.
        var remainingTime: TimeInterval { deadline - ProcessInfo.processInfo.systemUptime }
        let formulae = formulae.filter { $0.elevated == elevated }
        guard !formulae.isEmpty, remainingTime > 0, !Task.isCancelled else { return [] }

        let names = installedFormulae.map { installed in
            Set(installed.filter { name in
                formulae.contains { formula in
                    name == formula.name || formula.servicePrefix.map { name.hasPrefix($0) } == true
                }
            }).sorted()
        }
        if names?.isEmpty == true { return [] }

        let command = "\(elevated ? "sudo " : "")\(container.paths.brew) services info"
        var arguments = "--all"
        if let names {
            // Unlike services info with bare names, list --full-name resolves the
            // installed keg's tap. A third-party formula can also exist in core.
            let requested = names.map { "'\($0)'" }.joined(separator: " ")
            let resolved = await container.shell.pipe(
                "\(container.paths.brew) list --formula --full-name \(requested)", timeout: remainingTime
            )
            let fullNames = resolved.out.split(whereSeparator: \.isWhitespace).map(String.init)
            let resolvedNames = fullNames.compactMap { $0.split(separator: "/").last.map(String.init) }.sorted()
            if resolved.err.isEmpty && resolvedNames == names && fullNames.allSatisfy({
                $0.range(of: "^(?:[a-zA-Z0-9][a-zA-Z0-9_.-]*/[a-zA-Z0-9][a-zA-Z0-9_.-]*/)?[a-zA-Z0-9][a-zA-Z0-9@+_.-]*$",
                         options: .regularExpression) != nil
            }) {
                arguments = fullNames.map { "'\($0)'" }.joined(separator: " ")
            }
        }
        guard remainingTime > 0, !Task.isCancelled else { return [] }
        let output = await container.shell.pipe("\(command) \(arguments) --json", timeout: remainingTime)
        var services = try? JSONDecoder().decode([HomebrewService].self, from: Data(output.out.utf8))

        // An uninstall during the query, an unavailable formula definition, or an
        // older Homebrew can reject named queries. Keep the previous discovery path.
        if arguments != "--all" && (services == nil || !output.err.isEmpty) {
            guard remainingTime > 0, !Task.isCancelled else { return [] }
            Log.warn("Targeted Homebrew services query failed; retrying with --all.")
            let fallback = await container.shell.pipe("\(command) --all --json", timeout: remainingTime)
            services = try? JSONDecoder().decode([HomebrewService].self, from: Data(fallback.out.utf8))
        }

        guard let services else {
            Log.err("Failed to decode \(elevated ? "root" : "user") services JSON.")
            return []
        }

        return formulae.compactMap { $0.latestService(from: services) }
    }

    func getHomebrewService(named: String) async -> HomebrewService? {
        // Snapshot the actor's (Sendable) services and the main-actor `registry`
        // reference, then resolve the formula on the main actor. `HomebrewFormula`
        // is main-actor isolated, so it never leaves the main actor here; only the
        // Sendable `HomebrewService?` result crosses back to this actor.
        let services = homebrewServices
        let registry = self.registry

        return await MainActor.run {
            guard let formula = registry.formulae.first(where: { $0.name == named }) else {
                return services.first { $0.name == named }
            }

            return formula.latestService(from: services)
        }
    }
}
