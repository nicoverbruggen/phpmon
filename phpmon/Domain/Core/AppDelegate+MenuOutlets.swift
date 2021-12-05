//
//  AppDelegate+MenuOutlets.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 Any outlets connected to the app's main menu (not the menu that shows when the icon in
 the menu bar is clicked, but the regular app's main menu) are configured here.
 
 Default interactions like copy/paste, select all, close window etc. are wired up by
 default in the storyboard and do not need to be manually added.
 
 Extra functionality (like the menu item to reload the list of sites) does, however.
 
 - Note: This menu is only displayed when the app is NOT running in accessory mode.
 For more information about this, please see the ActivationPolicy-related extension.
 */
extension AppDelegate {
    
    // MARK: - Menu Interactions
    
    @IBAction func reloadSiteListPressed(_ sender: Any) {
        let vc = App.shared.siteListWindowController?
            .window?.contentViewController as? SiteListVC
        
        if vc != nil {
            // If the view exists, directly reload the list of sites
            vc!.reloadSites()
        } else {
            // If the view does not exist, reload the cached data that was populated when the app initially launched.
            Valet.shared.reloadSites()
        }
    }
    
}
