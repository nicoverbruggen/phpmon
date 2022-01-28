//
//  AppDelegate+InterApp.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
        // Only ever interpret the first URL
        if let url = urls.first {
            let command = url.absoluteString.replacingOccurrences(of: "phpmon://", with: "")
            
            switch (command) {
            case "list":
                SiteListVC.show()
                break
            default:
                break
            }
        }
    }
    
}

