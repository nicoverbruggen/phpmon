//
//  AppDelegate+InterApp.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Foundation

extension AppDelegate {

    /**
     This is an entry point for future development for integrating with the PHP Monitor
     application URL. You can use the `phpmon://` protocol to communicate with the app.
     
     At this time you can trigger the site list using Alfred (or some other application)
     by opening the following URL: `phpmon://list`.
     
     Please note that PHP Monitor needs to be running in the background for this to work.
     */
    func application(_ application: NSApplication, open urls: [URL]) {

        if !Preferences.isEnabled(.allowProtocolForIntegrations) {
            Log.info("Acting on commands via phpmon:// has been disabled.")
            return
        }

        guard let url = urls.first else { return }

        self.interpretCommand(
            url.absoluteString.replacingOccurrences(of: "phpmon://", with: ""),
            commands: InterApp.getCommands()
        )
    }

    private func interpretCommand(_ command: String, commands: [InterApp.Action]) {
        commands.forEach { action in
            if command.starts(with: action.command) {
                let lastElement = String(command.split(separator: "/").last!)
                action.action(lastElement)
            }
        }
    }
}
