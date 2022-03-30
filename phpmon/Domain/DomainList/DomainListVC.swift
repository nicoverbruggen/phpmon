//
//  DomainListVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Carbon

class DomainListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: - Variables
    
    /// List of sites that will be displayed in this view. Originates from the `Valet` object.
    var sites: [ValetSite] = []
    
    /// Array that contains various apps that might open a particular site directory.
    var applications: [Application] {
        return App.shared.detectedApplications
    }
    
    /// The last sort descriptor used.
    var sortDescriptor: NSSortDescriptor? = nil
    
    /// String that was last searched for. Empty by default.
    var lastSearchedFor = ""
    
    // MARK: - Helper Variables
    
    var selectedSite: ValetSite? {
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
            withIdentifier: "domainListWindow"
        ) as! DomainListWC
        
        windowController.window!.title = "domain_list.title".localized
        windowController.window!.subtitle = "domain_list.subtitle".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [
            .titled, .closable, .resizable, .miniaturizable
        ]
        windowController.window!.minSize = NSSize(width: 550, height: 200)
        windowController.window!.delegate = windowController
        windowController.window!.setFrameAutosaveName("domainListWindow")
        
        App.shared.domainListWindowController = windowController
    }
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.domainListWindowController == nil) {
            Self.create(delegate: delegate)
        }
        
        App.shared.domainListWindowController!.showWindow(self)
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
    
    func applySortDescriptor(_ descriptor: NSSortDescriptor) {
        sortDescriptor = descriptor
        
        var sorted = self.sites
        
        switch descriptor.key {
            case "Secure":
                sorted = self.sites.sorted { $0.secured && !$1.secured }; break
            case "Domain":
                sorted = self.sites.sorted { $0.absolutePath < $1.absolutePath }; break
            case "PHP":
                sorted = self.sites.sorted { $0.servingPhpVersion < $1.servingPhpVersion }; break
            case "Kind":
                sorted = self.sites.sorted { ($0.aliasPath == nil) && !($1.aliasPath == nil) }; break
            case "Type":
                sorted = self.sites.sorted { $0.driver ?? "ZZZ" < $1.driver ?? "ZZZ" }; break
            default: break;
        }
        
        self.sites = descriptor.ascending ? sorted.reversed() : sorted
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
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else { return }
        // Kinda scuffed way of applying sort descriptors here, but it works.
        Log.info("Applying sort descriptor for column: \(sortDescriptor.key ?? "Unknown")")
        applySortDescriptor(sortDescriptor)
        searchedFor(text: lastSearchedFor)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mapping: [String: String] = [
            "TLS": DomainListTLSCell.reusableName,
            "DOMAIN": DomainListNameCell.reusableName,
            "ENVIRONMENT": DomainListPhpCell.reusableName,
            "KIND": DomainListKindCell.reusableName,
            "TYPE": DomainListTypeCell.reusableName
        ]
        
        let columnName = tableColumn!.identifier.rawValue
        let identifier = NSUserInterfaceItemIdentifier(rawValue: mapping[columnName]!)
        
        guard let userCell = tableView.makeView(withIdentifier: identifier, owner: self)
            as? DomainListCellProtocol else { return nil }
        
        userCell.populateCell(with: sites[row])
        
        return userCell as? NSView
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
    
    func reloadTable() {
        if let sortDescriptor = sortDescriptor {
            self.applySortDescriptor(sortDescriptor)
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func searchedFor(text: String) {
        lastSearchedFor = text
        
        let searchString = text.lowercased()
        
        if searchString.isEmpty {
            sites = Valet.shared.sites
            
            reloadTable()
            
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
        
        reloadTable()
    }

    // MARK: - Deinitialization
    
    deinit {
        Log.perf("DomainListVC deallocated")
    }
}
