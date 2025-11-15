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
    private let data: ValetServicesDataManager

    override init(_ container: Container) {
        self.data = ValetServicesDataManager(container)
        super.init(container)

        // Load the initial services state
        Task {
            await self.reloadServicesStatus()

            await MainActor.run {
                firstRunComplete = true
            }
        }
    }

    override func reloadServicesStatus() async {
        // Fetch data on background (actor-isolated, thread-safe)
        let homebrewServices = await data.reloadServicesStatus(isRetry: false)

        // Update UI on main thread
        await MainActor.run {
            self.services = self.formulae.map { formula in
                Service(
                    formula: formula,
                    service: homebrewServices.first { $0.name == formula.name }
                )
            }

            self.broadcastServicesUpdated()
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
        await presentTroubleshootingForService(named: named)
    }

    @MainActor func presentTroubleshootingForService(named: String) async {
        // If we cannot get data from Homebrew, we won't be able to troubleshoot
        guard let after = await data.getHomebrewService(named: named) else {
            return
        }

        // If we don't get an error message from Homebrew, we won't be able to troubleshoot
        guard after.status == "error" else {
            return
        }

        Log.err("The service '\(named)' is now reporting an error.")

        // If we don't have a path to a log file, show a simplified alert
        guard let errorLogPath = after.error_log_path else {
            return NVAlert().withInformation(
                title: "alert.service_error.title".localized(named),
                subtitle: "alert.service_error.subtitle.no_error_log".localized(named),
                description: "alert.service_error.extra".localized
            )
            .withPrimary(text: "alert.service_error.button.close".localized)
            .show()
        }

        // If we do have a path to a log file, show a more complex alert w/ Show Log button
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
