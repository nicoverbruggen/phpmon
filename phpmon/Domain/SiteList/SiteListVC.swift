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
    
    /// List of sites that will be displayed in this view. Originates from the `Valet` object.
    var sites: [Valet.Site] = []
    
    /// Array that contains various apps that might open a particular site directory.
    var applications: [Application] {
        return App.shared.detectedApplications
    }
    
    /// String that was last searched for. Empty by default.
    var lastSearchedFor = ""
    
    // MARK: - Helper Variables
    
    var selectedSite: Valet.Site? {
        if tableView.selectedRow == -1 {
            return nil
        }
        return sites[tableView.selectedRow]
    }
    
    var timer: Timer? = nil
    
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
        windowController.window!.setFrameAutosaveName("siteListWindow")
        
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
        tableView.doubleAction = #selector(self.doubleClicked(sender:))
        if !Valet.shared.sites.isEmpty {
            // Preloaded list
            sites = Valet.shared.sites
            searchedFor(text: lastSearchedFor)
        } else {
            reloadSites()
        }
    }
    
    // MARK: - Async Operations
    
    /**
     Disables the UI so the user cannot interact with it.
     Also shows a spinner to indicate that we're busy.
     */
    private func setUIBusy() {
        // If it takes more than 0.5s to set the UI to not busy, show a spinner
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.progressIndicator.startAnimation(true)
        })
        
        tableView.alphaValue = 0.3
        tableView.isEnabled = false
        tableView.selectRowIndexes([], byExtendingSelection: true)
    }
    
    /**
     Re-enables the UI so the user can interact with it.
     */
    private func setUINotBusy() {
        timer?.invalidate()
        progressIndicator.stopAnimation(nil)
        tableView.alphaValue = 1.0
        tableView.isEnabled = true
    }
    
    /**
     Executes a specific callback and fires the completion callback,
     while updating the UI as required. As long as the completion callback
     does not fire, the app is presumed to be busy and the UI reflects this.
     
     - Parameter execute: Callback of the work that needs to happen.
     - Parameter completion: Callback that is fired when the work is done.
     */
    internal func waitAndExecute(_ execute: @escaping () -> Void, completion: @escaping () -> Void = {})
    {
        setUIBusy()
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            execute()
            
            // For a smoother animation, expect at least a 0.2 second delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                completion()
                setUINotBusy()
            }
        }
    }
    
    // MARK: - Site Data Loading
    
    func reloadSites() {
        waitAndExecute {
            Valet.shared.reloadSites()
        } completion: { [self] in
            sites = Valet.shared.sites
            searchedFor(text: lastSearchedFor)
        }
    }
    
    func addedNewSite(name: String, secure: Bool) {
        waitAndExecute {
            Valet.shared.reloadSites()
        } completion: { [self] in
            find(name, secure)
        }
    }
    
    private func find(_ name: String, _ secure: Bool = false) {
        sites = Valet.shared.sites
        searchedFor(text: "")
        if let site = sites.enumerated().first(where: { $0.element.name == name }) {
            DispatchQueue.main.async {
                self.tableView.selectRowIndexes([site.offset], byExtendingSelection: false)
                self.tableView.scrollRowToVisible(site.offset)
                if (secure && !site.element.secured) {
                    self.toggleSecure()
                }
            }
        }
    }
    
    // MARK: - Table View Delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self
        ) as? SiteListCell else { return nil }
        
        userCell.populateCell(with: sites[row])
        
        return userCell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        reloadContextMenu()
    }
    
    @objc func doubleClicked(sender: Any) {
        guard self.selectedSite != nil else {
            return
        }
        
        self.openInBrowser()
    }
    
    // MARK: - (Search) Text Field Delegate
    
    func searchedFor(text: String) {
        lastSearchedFor = text
        
        let searchString = text.lowercased()
        
        if searchString.isEmpty {
            sites = Valet.shared.sites
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        let splitSearchString: [String] = searchString
            .split(separator: " ")
            .map { return String($0) }
        
        sites = Valet.shared.sites.filter({ site in
            return !splitSearchString.map { searchString in
                return site.name.lowercased().contains(searchString)
            }.contains(false)
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Deinitialization
    
    deinit {
        Log.perf("SiteListVC deallocated")
    }
}
