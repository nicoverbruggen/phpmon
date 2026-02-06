//
//  AppDelegate+InterApp.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Foundation
import NVAlert

extension AppDelegate {

    /**
     This is an entry point for future development for integrating with the PHP Monitor
     application URL. You can use the `phpmon://` protocol to communicate with the app.

     At this time you can trigger the site list using Alfred (or some other application)
     by opening the following URL: `phpmon://list`.

     Please note that PHP Monitor needs to be running in the background for this to work.
     */
    @MainActor func application(_ application: NSApplication, open urls: [URL]) {
        if !Preferences.isEnabled(.allowProtocolForIntegrations) {
            if UserDefaults.standard.bool(forKey: PersistentAppState.didPromptForIntegrations.rawValue) {
                Log.info("Acting on commands via phpmon:// has been disabled.")
                return
            }

            Log.info("Acting on commands via phpmon:// has been disabled. Prompting user...")
            if !promptToEnableIntegrations() {
                return
            }
        }

        guard let url = urls.first else { return }

        self.interpretCommand(
            url.absoluteString.replacing("phpmon://", with: ""),
            commands: InterApp.getCommands()
        )
    }

    @MainActor private func promptToEnableIntegrations() -> Bool {
        UserDefaults.standard.set(true, forKey: PersistentAppState.didPromptForIntegrations.rawValue)
        UserDefaults.standard.synchronize()

        if !NVAlert()
            .withInformation(
                title: "alert.enable_integrations.title".localized,
                subtitle: "alert.enable_integrations.subtitle".localized,
                description: "alert.enable_integrations.desc".localized
            )
            .withPrimary(text: "alert.enable_integrations.ok".localized)
            .withSecondary(text: "alert.enable_integrations.cancel".localized)
            .didSelectPrimary(urgency: .bringToFront) {
            return false
        }

        Preferences.update(.allowProtocolForIntegrations, value: true)
        return true
    }

    private func interpretCommand(_ command: String, commands: [InterApp.Action]) {
        commands.forEach { action in
            if command.starts(with: action.command) {
                guard let lastElement = command.split(separator: "/").last else {
                    Log.warn("Ignoring malformed phpmon:// command: '\(command)'")
                    return
                }
                action.action(String(lastElement))
            }
        }
    }
}
