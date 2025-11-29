//
//  App+BrewWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension App {

    /**
     Performs a particular action while suspending the Homebrew watcher,
     until the task is completed.
     */
    public func withSuspendedHomebrewWatcher<T>(_ action: () async throws -> T) async rethrows -> T {
        await suspendHomebrewWatcher()
        defer { resumeHomebrewWatcher() }
        return try await action()
    }

    /**
     Prepares the `homebrew/bin` directory watcher. This allows PHP Monitor to quickly respond to
     external `brew` changes executed by the user.
     */
    public func prepareHomebrewWatchers() {
        let notifier = FSNotifier(
            for: URL(fileURLWithPath: container.paths.binPath),
            eventMask: .all,
            onChange: { Task { await self.onHomebrewPhpModification() } }
        )

        self.watchers["homebrewBinaries"] = notifier
        self.debouncers["homebrewBinaries"] = Debouncer()
    }

    private func suspendHomebrewWatcher() async {
        watchers["homebrewBinaries"]?.suspend()
        await debouncers["homebrewBinaries"]?.cancel()
    }

    private func resumeHomebrewWatcher() {
        watchers["homebrewBinaries"]?.resume()
    }

    public func onHomebrewPhpModification() async {
        if let debouncer = self.debouncers["homebrewBinaries"] {
            await debouncer.debounce(for: 5.0) {
                Log.info("No changes in `\(self.container.paths.binPath)` occurred for 5 seconds. Reloading now.")

                // We reload the PHP versions in the background
                await self.container.phpEnvs.reloadPhpVersions()

                // Finally, refresh the active installation
                await MainMenu.shared.refreshActiveInstallation()
            }
        }
    }

}
