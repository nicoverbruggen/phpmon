//
//  App+BrewWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension App {

    public func prepareHomebrewWatchers() {
        let notifier = FSNotifier(
            for: URL(fileURLWithPath: Paths.binPath),
            eventMask: .all,
            onChange: {
                Task { await self.onHomebrewPhpModification() }
                // Removing requires termination and then removing reference
                // self.watchers[.homebrewBinaries]?.terminate()
                // self.watchers[.homebrewBinaries] = nil
            }
        )

        App.shared.watchers[.homebrewBinaries] = notifier
    }

    public func onHomebrewPhpModification() async {
        #warning("This functionality working means that switcher code needs to change")
        let previous = PhpEnv.shared.currentInstall?.version.text
        Log.info("Something changed in the Homebrew binary directory...")
        await PhpEnv.detectPhpVersions()
        await MainMenu.shared.refreshActiveInstallation()
        let new = PhpEnv.shared.currentInstall?.version.text
        if previous != new {
            Log.info("The PHP version has changed, new version is now: \(new ?? "unlinked")")
            /*
             // These notifications will cause duplicate notifications if using the switcher
             if new != nil {
             LocalNotification.send(
             title: "Globally linked PHP version has changed!",
             subtitle: "PHP \(new!) is now active.",
             preference: nil
             )
             } else {
             LocalNotification.send(
             title: "Globally linked PHP version has changed!",
             subtitle: "PHP is now unlinked.",
             preference: nil
             )
             }
             */
        }
    }
}
