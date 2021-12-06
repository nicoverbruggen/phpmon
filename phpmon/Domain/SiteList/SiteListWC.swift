//
//  SiteListWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class SiteListWC: PMWindowController, NSSearchFieldDelegate, NSToolbarDelegate {
    
    // MARK: - Window Identifier
    
    override var windowName: String {
        return "SiteList"
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchToolbarItem: NSSearchToolbarItem!
    
    // MARK: - Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.searchToolbarItem.searchField.delegate = self
        self.searchToolbarItem.searchField.becomeFirstResponder()
    }
    
    // MARK: - Search functionality
    
    var contentVC: SiteListVC {
        return self.contentViewController as! SiteListVC
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchField = notification.object as? NSSearchField else {
            return
        }
        
        contentVC.searchedFor(text: searchField.stringValue)
    }
    
    // MARK: - Reload functionality
    
    @IBAction func pressedReload(_ sender: Any) {
        contentVC.reloadSites()
    }
}
