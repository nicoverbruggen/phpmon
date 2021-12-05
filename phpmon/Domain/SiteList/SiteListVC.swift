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
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: - Variables
    
    var sites: [Valet.Site] = []
    var editorAvailability: [String] = []
    var lastSearchedFor = ""
    
    // MARK: - Display
    
    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main" , bundle : nil)
        
        let windowController = storyboard.instantiateController(
            withIdentifier: "siteListWindow"
        ) as! SiteListWC
        
        windowController.window!.title = "site_list.title".localized
        windowController.window!.subtitle = "site_list.subtitle".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [
            .titled, .closable, .resizable, .miniaturizable
        ]
        windowController.window!.minSize = NSSize(width: 550, height: 200)
        windowController.window!.delegate = windowController
        
        App.shared.siteListWindowController = windowController
    }
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.siteListWindowController == nil) {
            Self.create(delegate: delegate)
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
        self.progressIndicator.stopAnimation(nil)
    }
    
    // MARK: - Site Data Loading
    
    func reloadSites() {
        // Start spinner and reset view (no items)
        self.progressIndicator.startAnimation(nil)
        self.tableView.alphaValue = 0.3
        self.tableView.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            // Reload site information
            Valet.shared.reloadSites()
            
            DispatchQueue.main.async { [self] in
                // Update the site list
                self.sites = Valet.shared.sites
                
                // Stop spinner
                self.progressIndicator.stopAnimation(nil)
                self.tableView.alphaValue = 1.0
                self.tableView.isEnabled = true
                
                // Re-apply any existing search
                self.searchedFor(text: lastSearchedFor)
            }
        }
    }
    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.sites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self) as? SiteListCell else { return nil }
        
        let item = self.sites[row]
        
        /// Make sure to show the TLD
        userCell.labelSiteName.stringValue = "\(item.name!).\(Valet.shared.config.tld)"
        
        /// Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        userCell.labelPathName.stringValue = item.absolutePath
            .replacingOccurrences(of: "/Users/\(Paths.whoami)", with: "~")
        
        /// If the `aliasPath` is nil, we're dealing with a parked site. Otherwise, it's a link that was explicitly created.
        userCell.imageViewType.image = NSImage(
            named: item.aliasPath == nil
            ? "IconParked"
            : "IconLinked"
        )
        userCell.imageViewType.contentTintColor = NSColor.tertiaryLabelColor
        
        /// Show the green or red lock based on whether the site was secured
        userCell.imageViewLock.contentTintColor = item.secured ? NSColor.systemGreen
            : NSColor.red
        
        /// Show the current driver
        userCell.labelDriver.stringValue = item.driver
        
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
            action: #selector(toggleSecure),
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
    
    @objc public func toggleSecure() {
        let rowToReload = self.tableView.selectedRow
        let site = self.sites[self.tableView.selectedRow]
        let previous = site.secured
        let action = site.secured ? "unsecure" : "secure"
        
        self.progressIndicator.startAnimation(nil)
        self.tableView.alphaValue = 0.3
        self.tableView.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let command = "cd \(site.absolutePath!) && sudo \(Paths.valet) \(action) && exit;"
            let _ = Shell.pipe(command, requiresPath: true)
            
            site.determineSecured(Valet.shared.config.tld)
            
            DispatchQueue.main.async { [self] in
                if site.secured == previous {
                    Alert.notify(
                        message: "SSL status not changed",
                        info: "Something went wrong. Try running the command in your terminal manually: `\(command)`")
                } else {
                    let newState = site.secured ? "secured" : "unsecured"
                    LocalNotification.send(
                        title: "SSL status changed",
                        subtitle: "The domain '\(site.name!).\(Valet.shared.config.tld)' is now \(newState)."
                    )
                }
                
                progressIndicator.stopAnimation(nil)
                self.tableView.alphaValue = 1
                self.tableView.isEnabled = true
                
                tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0])
                tableView.deselectRow(rowToReload)
                tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
            }
        }
    }
    
    // MARK: Open with IDE / Editor
    
    @objc public func openWithPhpStorm() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("open -a /Applications/PhpStorm.app \(site.absolutePath!)")
    }
    
    @objc public func openWithVSCode() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("/usr/local/bin/code \(site.absolutePath!)")
    }
    
    // MARK: Open in Browser & Finder
    
    @objc public func openInBrowser() {
        let site = self.sites[self.tableView.selectedRow]
        let prefix = site.secured ? "https://" : "http://"
        let url = "\(prefix)\(site.name!).\(Valet.shared.config.tld)"
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @objc public func openInFinder() {
        let site = self.sites[self.tableView.selectedRow]
        Shell.run("open \(site.absolutePath!)")
    }
    
    // MARK: - (Search) Text Field Delegate
    
    func searchedFor(text: String) {
        self.lastSearchedFor = text
        
        let searchString = text.lowercased()
        
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
