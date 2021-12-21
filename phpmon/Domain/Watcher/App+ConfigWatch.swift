//
//  App+ConfigWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
        let url = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(PhpSwitcher.phpInstall.version.short)")
        
        // Watcher needs to be created
        if self.watcher == nil {
            startWatcher(url)
        }
        
        // Watcher needs to be updated
        if self.watcher.url != url || forceReload {
            self.watcher.disable()
            self.watcher = nil
            Log.info("Watcher has stopped watching files. Starting new one...")
            startWatcher(url)
        }
    }
    
}
