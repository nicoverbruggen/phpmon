//
//  SiteListWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class SiteListWC: NSWindowController, NSSearchFieldDelegate, NSToolbarDelegate {
    
    @IBOutlet weak var searchToolbarItem: NSSearchToolbarItem!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.searchToolbarItem.searchField.delegate = self
        self.searchToolbarItem.searchField.becomeFirstResponder()
    }
    
    var contentVC: SiteListVC {
        return self.contentViewController as! SiteListVC
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchField = notification.object as? NSSearchField else {
            print("Unexpected control in update notification")
            return
        }
        
        contentVC.searchedFor(text: searchField.stringValue)
    }
    
    @IBAction func pressedReload(_ sender: Any) {
        contentVC.reloadSites()
    }
}
