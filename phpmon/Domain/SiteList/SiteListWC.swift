//
//  SiteListWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class SiteListWC: NSWindowController, NSSearchFieldDelegate {
    
    @IBOutlet weak var searchToolbarItem: NSSearchToolbarItem!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.searchToolbarItem.searchField.delegate = self
        self.searchToolbarItem.searchField.becomeFirstResponder()
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchField = notification.object as? NSSearchField else {
            print("Unexpected control in update notification")
            return
        }
        
        let window = self.contentViewController as! SiteListVC
        window.searchedFor(text: searchField.stringValue)
    }
    
}
