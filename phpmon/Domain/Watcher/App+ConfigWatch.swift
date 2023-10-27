//
//  App+ConfigWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension App {

    func startWatchManager(_ url: URL) {
        Log.perf("Starting config watch manager...")
        self.watchManager = ConfigWatchManager(for: url)

        self.watchManager.didChange = { url in
            Log.perf("Something has changed in: \(url)")

            // Check if the watcher has last updated the menu less than 0.75s ago
            let distance = self.watchManager.lastUpdate?.distance(to: Date().timeIntervalSince1970)
            if distance == nil || distance != nil && distance! > 0.75 {
                Log.perf("Refreshing menu...")
                Task { @MainActor in MainMenu.shared.reloadPhpMonitorMenuInBackground() }
                self.watchManager.lastUpdate = Date().timeIntervalSince1970
            }
        }
    }

    func handlePhpConfigWatcher(forceReload: Bool = false) {
        if ActiveFileSystem.shared is TestableFileSystem {
            Log.warn("Config watch manager is disabled when using testable filesystem.")
            return
        }

        guard let install = PhpEnvironments.phpInstall else {
            Log.info("It appears as if no PHP installation is currently active.")
            Log.info("The config watch manager be disabled until a PHP install is active.")
            return
        }

        let url = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(install.version.short)")

        // Check whether the manager exists and schedule on the main thread
        // if we don't consistently do this, the app will create duplicate watchers
        // due to timing issues, which creates retain cycles
        Task { @MainActor in
            // Watcher needs to be created
            if self.watchManager == nil {
                self.startWatchManager(url)
            }

            // Watcher needs to be updated
            if self.watchManager.url != url || forceReload {
                self.watchManager.disable()
                self.watchManager = nil
                Log.perf("Watcher has stopped watching files. Starting new one...")
                self.startWatchManager(url)
            }
        }
    }

}
