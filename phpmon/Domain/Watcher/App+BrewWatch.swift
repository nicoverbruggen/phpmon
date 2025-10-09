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
            for: URL(fileURLWithPath: container.paths.binPath),
            eventMask: .all,
            onChange: { Task { await self.onHomebrewPhpModification() } }
        )

        App.shared.watchers["homebrewBinaries"] = notifier
    }

    public func destroyHomebrewWatchers() {
        // Removing requires termination and then removing reference
        self.watchers["homebrewBinaries"]?.terminate()
        self.watchers["homebrewBinaries"] = nil
    }

    public func onHomebrewPhpModification() async {
        // let previous = PhpEnvironments.shared.currentInstall?.version.text
        Log.info("Something changed in the Homebrew binary directory...")
        await PhpEnvironments.detectPhpVersions()
        await MainMenu.shared.refreshActiveInstallation()

        //
        // TODO: PHP Guard 2.0
        // Check if the new and previous version of PHP are different
        // if so, we can show a notification if needed or alert the user
        //
        // let new = PhpEnvironments.shared.currentInstall?.version.text
        //
    }
}
