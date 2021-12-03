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
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    
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
    
    override func viewDidLoad() {}
    
    override func viewWillAppear() {}
    
    override func viewWillDisappear() {}
    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return Valet.shared.sites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self) as? SiteListCell else { return nil }
        
        let item = Valet.shared.sites[row]
        
        /// Make sure to show the TLD
        userCell.labelSiteName.stringValue = "\(item.name).\(Valet.shared.config.tld)"
        
        /// Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        userCell.labelPathName.stringValue = item.absolutePath
            .replacingOccurrences(of: "/Users/\(Paths.whoami)", with: "~")
        
        /// If the `aliasPath` is nil, we're dealing with a parked site. Otherwise, it's a link that was explicitly created.
        userCell.labelSiteType.stringValue = item.aliasPath == nil
            ? "Parked Site"
            : "Linked Site"
        
        /// Show the green or red lock based on whether the site was secured
        userCell.imageViewLock.image = NSImage(named: item.secured ? "GreenLock" : "RedLock")
        
        /// TODO: Load the correct PHP version (not determined as of yet)
        userCell.labelPhpVersion.stringValue = "PHP 8.0"
        
        return userCell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let menu = NSMenu()
        
        let site = Valet.shared.sites[self.tableView.selectedRow]
        
        if self.tableView.selectedRow == -1 {
            tableView.menu = nil
            return
        }
        
        menu.addItem(
            withTitle: site.secured ? "Unsecure" : "Secure",
            action: #selector(self.secure),
            keyEquivalent: "L"
        )
        menu.addItem(
            withTitle: "Open in Browser...",
            action: #selector(self.openInBrowser),
            keyEquivalent: "O"
        )
        tableView.menu = menu
    }
    
    @objc public func secure() {
        
    }
    
    @objc public func openInBrowser() {
        if self.tableView.selectedRow == -1 {
            return
        }
        
        let site = Valet.shared.sites[self.tableView.selectedRow]
        let prefix = site.secured ? "https://" : "http://"
        let url = "\(prefix)\(site.name).\(Valet.shared.config.tld)"
        NSWorkspace.shared.open(URL(string: url)!)
    }

    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}
