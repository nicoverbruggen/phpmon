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

class SiteListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var textFieldSearch: NSTextField!
    
    @IBOutlet weak var tableView: NSTableView!
    
    public var editorAvailability: [String] = []
    
    public var sites: [Valet.Site] = []
    
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
    
    override func viewDidLoad() {
        if (Shell.fileExists("/usr/local/bin/code")) {
            self.editorAvailability.append("vscode")
        }
        
        if (Shell.fileExists("/Applications/PhpStorm.app/Contents/Info.plist")) {
            self.editorAvailability.append("phpstorm")
        }
        self.sites = Valet.shared.sites
    }
    
    override func viewWillAppear() {}
    
    override func viewWillDisappear() {}
    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.sites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self) as? SiteListCell else { return nil }
        
        let item = self.sites[row]
        
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
        
        if self.tableView.selectedRow == -1 {
            tableView.menu = nil
            return
        }
        
        let site = self.sites[self.tableView.selectedRow]
        
        menu.addItem(
            withTitle: site.secured
                ? "site_list.unsecure".localized
                : "site_list.secure".localized,
            action: #selector(self.secure),
            keyEquivalent: "L"
        )
        
        if (self.editorAvailability.count > 0) {
            menu.addItem(NSMenuItem.separator())
            
            if self.editorAvailability.contains("vscode") {
                menu.addItem(
                    withTitle: "site_list.open_with_vs_code".localized,
                    action: #selector(self.openWithVSCode),
                    keyEquivalent: ""
                )
            }
            
            if editorAvailability.contains("phpstorm") {
                menu.addItem(
                    withTitle: "site_list.open_with_pstorm".localized,
                    action: #selector(self.openWithPhpStorm),
                    keyEquivalent: ""
                )
            }
            
            menu.addItem(NSMenuItem.separator())
        }
        
        menu.addItem(
            withTitle: "site_list.open_in_finder".localized,
            action: #selector(self.openInFinder),
            keyEquivalent: "F"
        )
        menu.addItem(
            withTitle: "site_list.open_in_browser".localized,
            action: #selector(self.openInBrowser),
            keyEquivalent: "O"
        )
        tableView.menu = menu
    }
    
    // MARK: Secure / unsecure
    
    @objc public func secure() {
        
    }
    
    // MARK: Open with IDE / Editor
    
    @objc public func openWithPhpStorm() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("open -a /Applications/PhpStorm.app \(site.absolutePath)")
    }
    
    @objc public func openWithVSCode() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("/usr/local/bin/code \(site.absolutePath)")
    }
    
    // MARK: Open in Browser & Finder
    
    @objc public func openInBrowser() {
        let site = self.sites[self.tableView.selectedRow]
        let prefix = site.secured ? "https://" : "http://"
        let url = "\(prefix)\(site.name).\(Valet.shared.config.tld)"
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @objc public func openInFinder() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("open \(site.absolutePath)")
    }
    
    // MARK: - (Search) Text Field Delegate
    
    func controlTextDidChange(_ obj: Notification) {
        let searchString = self.textFieldSearch.stringValue.lowercased()
        
        if searchString.isEmpty {
            self.sites = Valet.shared.sites
            tableView.reloadData()
            return
        }
        
        self.sites = Valet.shared.sites.filter({ site in
            return site.name.lowercased().contains(searchString)
        })
        
        tableView.reloadData()
    }

    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}
