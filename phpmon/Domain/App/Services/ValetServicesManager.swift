//
//  ValetServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import NVAlert

class ValetServicesManager: ServicesManager {

    override init(_ container: Container) {
        super.init(container)

        // Load the initial services state
        Task {
            await self.reloadServicesStatus()

            Task { @MainActor in
                firstRunComplete = true
            }
        }
    }

    /**
     The last known state of all Homebrew services.
     */
    var homebrewServices: [HomebrewService] = []

    /**
     This method allows us to reload the Homebrew services, but we run this command
     twice (once for user services, and once for root services). Please note that
     these two commands are executed concurrently.

     If this fails, question marks will be displayed in the menu bar and we will
     try one more time to reload the services.
     */
    override func reloadServicesStatus() async {
        await reloadServicesStatus(isRetry: false)
    }

    private func reloadServicesStatus(isRetry: Bool) async {
        if !Valet.installed {
            return Log.info("Not reloading services because running in Standalone Mode.")
        }

        await withTaskGroup(of: [HomebrewService].self, body: { group in
            // Retrieve the status of the formulae that run as root
            group.addTask {
                await self.fetchHomebrewServices(elevated: true)
            }

            // At the same time, retrieve the status of the formulae that run as user
            group.addTask {
                await self.fetchHomebrewServices(elevated: false)
            }

            // Ensure that Homebrew services' output is stored
            self.homebrewServices = []

            for await services in group {
                homebrewServices.append(contentsOf: services)
            }

            // If we didn't get any service data and this isn't a retry, try again
            if self.homebrewServices.isEmpty && !isRetry {
                Log.warn("Failed to retrieve any Homebrew services data. Retrying once in 2 seconds...")
                await delay(seconds: 2)
                await self.reloadServicesStatus(isRetry: true)
                return
            }

            // Dispatch the update of the new service wrappers
            Task { @MainActor in
                // Ensure both commands complete (but run concurrently)
                services = formulae.map { formula in
                    Service(
                        formula: formula,
                        service: homebrewServices.first(where: { service in
                            service.name == formula.name
                        })
                    )
                }

                // Broadcast that all services have been updated
                self.broadcastServicesUpdated()
            }
        })
    }

    /**
     Fetches Homebrew services information for either elevated (root) or user services.

     - Parameter elevated: Whether to fetch services running as root (true) or user (false)
     - Returns: Array of HomebrewService objects, or empty array if fetching fails
     */
    private func fetchHomebrewServices(elevated: Bool) async -> [HomebrewService] {
        // Check which formulae we are supposed to be looking for
        let serviceNames = self.formulae
            .filter { $0.elevated == elevated }
            .map { $0.name }

        // Determine which command to run
        let command = elevated
            ? "sudo \(self.container.paths.brew) services info --all --json"
            : "\(self.container.paths.brew) services info --all --json"

        // Run and get the output of the command
        let output = await self.container.shell.pipe(command).out

        // Attempt to parse the output
        guard let jsonData = output.data(using: .utf8) else {
            Log.err("Failed to convert \(elevated ? "root" : "user") services output to UTF-8 data. Output: \(output)")
            return []
        }

        // Attempt to decode the JSON output. In certain situations the output may not be valid and this prevents a crash
        do {
            return try JSONDecoder()
                .decode([HomebrewService].self, from: jsonData)
                .filter { serviceNames.contains($0.name) }
        } catch {
            Log.err("Failed to decode \(elevated ? "root" : "user") services JSON: \(error). Output: \(output)")
            return []
        }
    }

    override func toggleService(named: String) async {
        guard let wrapper = self[named] else {
            return Log.err("The wrapper for '\(named)' is missing.")
        }

        // Normally, we allow starting and stopping
        var action = wrapper.status == .active ? "stop" : "start"

        // However, if we've encountered an error, attempt to restart
        if wrapper.status == .error {
            action = "restart"
        }

        // Run the command
        await brew(
            container,
            "services \(action) \(wrapper.formula.name)",
            sudo: wrapper.formula.elevated
        )

        // Reload the services status to confirm this worked
        await ServicesManager.shared.reloadServicesStatus()

        Task {
            await presentTroubleshootingForService(named: named)
        }
    }

    @MainActor func presentTroubleshootingForService(named: String) {
        let after = self.homebrewServices.first { service in
            return service.name == named
        }

        guard let after else { return }

        if after.status == "error" {
            Log.err("The service '\(named)' is now reporting an error.")

            guard let errorLogPath = after.error_log_path else {
                return NVAlert().withInformation(
                    title: "alert.service_error.title".localized(named),
                    subtitle: "alert.service_error.subtitle.no_error_log".localized(named),
                    description: "alert.service_error.extra".localized
                )
                .withPrimary(text: "alert.service_error.button.close".localized)
                .show()
            }

            NVAlert().withInformation(
                title: "alert.service_error.title".localized(named),
                subtitle: "alert.service_error.subtitle.error_log".localized(named),
                description: "alert.service_error.extra".localized
            )
            .withPrimary(text: "alert.service_error.button.close".localized)
            .withTertiary(text: "alert.service_error.button.show_log".localized, action: { alert in
                let url = URL(fileURLWithPath: errorLogPath)
                if errorLogPath.hasSuffix(".log") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                alert.close(with: .OK)
            })
            .show()
        }
    }
}
