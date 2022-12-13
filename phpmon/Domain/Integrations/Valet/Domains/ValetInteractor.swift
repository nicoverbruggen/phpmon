//
//  ValetInteractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ValetInteractionError: Error {
    /// The command the user should try (and failed).
    var command: String
}

#warning("ValetInteractor needs to be implemented and used")
class ValetInteractor {
    public static func toggleSecure(site: ValetSite) async throws {
        // TODO
    }

    public static func toggleSecure(proxy: ValetProxy) async throws {
        // Keep track of the original status (secure or not?)
        let originalSecureStatus = proxy.secured

        // Build the list of commands we will need to run
        let commands: [String] = [
            // Unproxy the given domain
            "\(Paths.valet) unproxy \(proxy.domain)",
            // Re-create the proxy (with the inverse secured status)
            originalSecureStatus
                ? "\(Paths.valet) proxy \(proxy.domain) \(proxy.target)"
                : "\(Paths.valet) proxy \(proxy.domain) \(proxy.target) --secure"
        ]

        for command in commands {
            await Shell.quiet(command)
        }

        // Check if the secured status has actually changed
        proxy.determineSecured()
        if proxy.secured == originalSecureStatus {
            throw ValetInteractionError(
                command: commands.joined(separator: " && ")
            )
        }

        // Restart nginx to load the new configuration
        await Actions.restartNginx()
    }

    public static func isolate(site: ValetSite, version: PhpVersionNumber) async throws {
        // TODO
    }

    public static func unlink(site: ValetSite) async throws {
        // TODO
    }

    public static func remove(proxy: ValetProxy) async throws {
        await Shell.quiet("valet unproxy '\(proxy.domain)'")
    }
}
