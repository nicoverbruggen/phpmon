//
//  App+ConfigWatch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import PMCommon

extension App {
    
    func startWatcher(_ url: URL) {
        print("No watcher currently active...")
        self.watcher = PhpConfigWatcher(for: url)
        
        self.watcher.didChange = { url in
            print("Something has changed in: \(url)")
            
            // Check if the watcher has last updated the menu less than 0.75s ago
            let distance = self.watcher.lastUpdate?.distance(to: Date().timeIntervalSince1970)
            if distance == nil || distance != nil && distance! > 0.75 {
                print("Refreshing menu...")
                MainMenu.shared.reloadPhpMonitorMenuInBackground()
                self.watcher.lastUpdate = Date().timeIntervalSince1970
            }
        }
    }
    
    func handlePhpConfigWatcher(forceReload: Bool = false) {
        if self.currentInstall != nil {
            // Determine the path of the config folder
            let url = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(self.currentInstall!.version.short)")
            
            // Watcher needs to be created
            if self.watcher == nil {
                startWatcher(url)
            }
            
            // Watcher needs to be updated
            if self.watcher.url != url || forceReload {
                self.watcher.disable()
                self.watcher = nil
                print("Watcher has stopped watching files. Starting new one...")
                startWatcher(url)
            }
        }
    }
    
}
