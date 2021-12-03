//
//  SiteListVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

class SiteListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    // MARK: - Display
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.siteListWindowController == nil) {
            let vc = NSStoryboard(name: "Main", bundle: nil)
                .instantiateController(withIdentifier: "siteList") as! SiteListVC
            let window = NSWindow(contentViewController: vc)
            
            window.title = "site_list.title".localized
            window.delegate = delegate
            window.styleMask = [.titled, .closable, .resizable]
            
            App.shared.siteListWindowController = SiteListWC(window: window)
        }
        
        App.shared.siteListWindowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear() {

    }
    
    override func viewWillDisappear() {

    }
    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return Valet.shared.linkedSites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self) as? SiteListCell else { return nil }
        
        let item = Valet.shared.linkedSites[row]
        
        userCell.labelSiteName.stringValue = "\(item.name).\(Valet.shared.config.tld)"
        userCell.labelPathName.stringValue = item.absolutePath
        
        userCell.labelSiteType.isHidden = true
        userCell.labelPhpVersion.isHidden = true
        
        return userCell
    }


    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}
