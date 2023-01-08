//
//  ValetServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class ValetServicesManager: ServicesManager {
    override init() {
        super.init()

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
     */
    override func reloadServicesStatus() async {
        await withTaskGroup(of: [HomebrewService].self, body: { group in
            // First, retrieve the status of the formulae that run as root
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

            // At the same time, retrieve the status of the formulae that run as user
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

            // Ensure that Homebrew services' output is stored
            self.homebrewServices = []
            for await services in group {
                homebrewServices.append(contentsOf: services)
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

    override func toggleService(named: String) async {
        guard let wrapper = self[named] else {
            return Log.err("The wrapper for '\(named)' is missing.")
        }

        // Prepare the appropriate command to stop or start a service
        let before = self.homebrewServices.first { service in
            return service.name == named
        }

        // Normally, we allow starting and stopping
        var action = wrapper.status == .active ? "stop" : "start"

        // However, if we've encountered an error, attempt to restart
        if wrapper.status == .error {
            action = "restart"
        }

        let command = "services \(action) \(wrapper.formula.name)"

        // Run the command
        await brew(command, sudo: wrapper.formula.elevated)

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
                return BetterAlert().withInformation(
                    title: "alert.service_error.title".localized(named),
                    subtitle: "alert.service_error.subtitle.no_error_log".localized(named),
                    description: "alert.service_error.extra".localized
                )
                .withPrimary(text: "alert.service_error.button.close".localized)
                .show()
            }

            BetterAlert().withInformation(
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
