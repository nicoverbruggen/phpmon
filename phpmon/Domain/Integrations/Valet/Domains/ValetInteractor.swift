//
//  ValetInteractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ValetInteractionError: Error {
    /// The command the user should try (and failed).
    var command: String
}

class ValetInteractor {
    static var shared = ValetInteractor()

    public static func useFake() {
        ValetInteractor.shared = FakeValetInteractor()
    }

    // MARK: - Managing Domains

    public func link(path: String, domain: String) async throws {
        await Shell.quiet("cd '\(path)' && \(Paths.valet) link '\(domain)' && valet links")
    }

    public func unlink(site: ValetSite) async throws {
        await Shell.quiet("valet unlink '\(site.name)'")
    }

    public func proxy(domain: String, proxy: String, secure: Bool) async throws {
        let command = secure
            ? "\(Paths.valet) proxy \(domain) \(proxy) --secure"
            : "\(Paths.valet) proxy \(domain) \(proxy)"

        await Shell.quiet(command)
        await Actions.restartNginx()
    }

    public func remove(proxy: ValetProxy) async throws {
        await Shell.quiet("valet unproxy '\(proxy.domain)'")
    }

    // MARK: - Modifying Domains

    public func toggleSecure(site: ValetSite) async throws {
        // Keep track of the original status (secure or not?)
        let originalSecureStatus = site.secured

        // Keep track of the command we wish to run
        let action = site.secured ? "unsecure" : "secure"

        // Use modernized version of command using domain name
        // This will allow us to secure multiple domains that use the same path
        var command = "sudo \(Paths.valet) \(action) '\(site.name)' && exit;"

        // For Valet 2, use the old syntax; this has a known issue so Valet 3+ is preferred
        if !Valet.enabled(feature: .isolatedSites) {
            command = "cd '\(site.absolutePath)' && sudo \(Paths.valet) \(action) && exit;"
        }

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

    public func isolate(site: ValetSite, version: String) async throws {
        let command = "sudo \(Paths.valet) isolate php@\(version) --site '\(site.name)'"

        // Run the command
        await Shell.quiet(command)

        // Check if the secured status has actually changed
        site.determineIsolated()
        site.determineComposerPhpVersion()

        // If the version is not isolated, this failed
        if site.isolatedPhpVersion == nil {
            throw ValetInteractionError(command: command)
        }
    }

    public func unisolate(site: ValetSite) async throws {
        let command = "sudo \(Paths.valet) unisolate --site '\(site.name)'"

        // Run the command
        await Shell.quiet(command)

        // Check if the secured status has actually changed
        site.determineIsolated()
        site.determineComposerPhpVersion()

        // If the version is somehow still isolated, this failed
        if site.isolatedPhpVersion != nil {
            throw ValetInteractionError(command: command)
        }
    }
}
