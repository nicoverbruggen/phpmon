//
//  App+ConfigWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension App {

    func startWatcher(_ url: URL) {
        Log.info("No watcher currently active...")
        self.watcher = PhpConfigWatcher(for: url)

        self.watcher.didChange = { url in
            Log.info("Something has changed in: \(url)")

            // Check if the watcher has last updated the menu less than 0.75s ago
            let distance = self.watcher.lastUpdate?.distance(to: Date().timeIntervalSince1970)
            if distance == nil || distance != nil && distance! > 0.75 {
                Log.info("Refreshing menu...")
                MainMenu.shared.reloadPhpMonitorMenuInBackground()
                self.watcher.lastUpdate = Date().timeIntervalSince1970
            }
        }
    }

    func handlePhpConfigWatcher(forceReload: Bool = false) {
        let url = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(PhpEnv.phpInstall.version.short)")

        // Check whether the watcher exists and schedule on the main thread
        // if we don't consistently do this, the app will create duplicate watchers
        // due to timing issues, which creates retain cycles.
        DispatchQueue.main.async {
            // Watcher needs to be created
            if self.watcher == nil {
                self.startWatcher(url)
            }

            // Watcher needs to be updated
            if self.watcher.url != url || forceReload {
                self.watcher.disable()
                self.watcher = nil
                Log.info("Watcher has stopped watching files. Starting new one...")
                self.startWatcher(url)
            }
        }
    }

}
