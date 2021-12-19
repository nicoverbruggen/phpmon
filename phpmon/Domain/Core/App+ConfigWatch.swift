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
        print("No watcher currently active...")
        self.watcher = PhpConfigWatcher(for: url)
        
        self.watcher.didChange = { url in
            // TODO: Make sure this is debounced, because a single process may update the config file many times; this occurs when installing Xdebug, for example
            print("Something has changed in: \(url)")
            MainMenu.shared.reloadPhpMonitorMenuInBackground()
        }
    }
    
    func handlePhpConfigWatcher() {
        if self.currentInstall != nil {
            // Determine the path of the config folder
            let url = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(self.currentInstall!.version.short)")
            
            // Watcher needs to be created
            if self.watcher == nil {
                startWatcher(url)
            }
            
            // Watcher needs to be updated
            if self.watcher.url != url {
                self.watcher.disable()
                self.watcher = nil
                print("Watcher has stopped watching files. Starting new one...")
                startWatcher(url)
            }
        }
    }
    
}
