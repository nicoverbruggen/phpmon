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
    static var shared = ValetInteractor()

    public static func useFake() {
        ValetInteractor.shared = FakeValetInteractor()
    }

    public func toggleSecure(site: ValetSite) async throws {
        // Keep track of the original status (secure or not?)
        let originalSecureStatus = site.secured

        // Keep track of the command we wish to run
        let action = site.secured ? "unsecure" : "secure"
        let command = "cd '\(site.absolutePath)' && sudo \(Paths.valet) \(action) && exit;"

        // Run the command
        await Shell.quiet(command)

        // Check if the secured status has actually changed
        site.determineSecured()
        if site.secured == originalSecureStatus {
            throw ValetInteractionError(command: command)
        }
    }

    public func toggleSecure(proxy: ValetProxy) async throws {
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

        // Run the commands
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

    public func isolate(site: ValetSite, version: PhpVersionNumber) async throws {
        // TODO
    }

    public func unlink(site: ValetSite) async throws {
        // TODO
    }

    public func remove(proxy: ValetProxy) async throws {
        await Shell.quiet("valet unproxy '\(proxy.domain)'")
    }
}

class FakeValetInteractor: ValetInteractor {
    override func toggleSecure(proxy: ValetProxy) async throws {
        proxy.secured = !proxy.secured
    }

    override func toggleSecure(site: ValetSite) async throws {
        site.secured = !site.secured
    }

    override func remove(proxy: ValetProxy) async throws {
        fatalError("This should remove the proxy")
    }
}
