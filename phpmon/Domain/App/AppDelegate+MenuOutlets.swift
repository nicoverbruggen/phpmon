//
//  AppDelegate+MenuOutlets.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

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

    @IBAction func addSiteLinkPressed(_ sender: Any) {
        DomainListVC.show()

        guard let windowController = App.shared.domainListWindowController else { return }
        windowController.pressedAddLink(nil)
    }

    @IBAction func reloadDomainListPressed(_ sender: Any) {
        Task { // Reload domains
            let vc = App.shared.domainListWindowController?
                .window?.contentViewController as? DomainListVC

            if vc != nil {
                // If the view exists, directly reload the list of sites.
                await vc!.reloadDomains()
            } else {
                // If the view does not exist, reload the cached data that was populated when the app launched.
                await Valet.shared.reloadSites()
            }
        }
    }

    @IBAction func focusSearchField(_ sender: Any) {
        DomainListVC.show()

        guard let windowController = App.shared.domainListWindowController else { return }
        windowController.searchToolbarItem.searchField.becomeFirstResponder()
    }

}
