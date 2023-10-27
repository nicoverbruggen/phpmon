//
//  DomainListVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Carbon

class DomainListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    // MARK: - Outlets

    @IBOutlet weak var tableView: PMTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    // MARK: - Variables

    /// List of sites that will be displayed in this view. Originates from the `Valet` object.
    var domains: [ValetListable] = []

    /// Array that contains various apps that might open a particular site directory.
    var applications: [Application] {
        return App.shared.detectedApplications
    }

    /// The last sort descriptor used.
    var sortDescriptor: NSSortDescriptor?

    /// String that was last searched for. Empty by default.
    var lastSearchedFor = ""

    // MARK: - Helper Variables

    var selectedSite: ValetSite? {
        if tableView.selectedRow == -1 {
            return nil
        }
        return domains[tableView.selectedRow] as? ValetSite
    }

    var selectedProxy: ValetProxy? {
        if tableView.selectedRow == -1 {
            return nil
        }
        return domains[tableView.selectedRow] as? ValetProxy
    }

    var selected: ValetListable? {
        if tableView.selectedRow == -1 {
            return nil
        }
        return domains[tableView.selectedRow]
    }

    var timer: Timer?

    // MARK: - Display

    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        let windowController = storyboard.instantiateController(
            withIdentifier: "domainListWindow"
        ) as! DomainListWindowController

        guard let window = windowController.window else { return }

        window.title = "domain_list.title".localized
        window.subtitle = "domain_list.subtitle".localized
        window.delegate = delegate ?? windowController
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.minSize = NSSize(width: 550, height: 200)
        window.setFrameAutosaveName("domainListWindow")

        App.shared.domainListWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.domainListWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.domainListWindowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        App.shared.domainListWindowController?.window?.orderFrontRegardless()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        tableView.doubleAction = #selector(self.doubleClicked(sender:))

        let mapping = [
            "SECURE": "domain_list.columns.secure",
            "DOMAIN": "domain_list.columns.domain",
            "ENVIRONMENT": "domain_list.columns.php",
            "KIND": "domain_list.columns.kind",
            "TYPE": "domain_list.columns.project_type"
        ]

        for (id, key) in mapping {
            let column = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id))
            column?.title = key.localized
        }

        if !Valet.shared.sites.isEmpty {
            // Preloaded list
            domains = Valet.getDomainListable()
            searchedFor(text: lastSearchedFor)
        } else {
            Task { await reloadDomains() }
        }
    }

    // MARK: - Async Operations

    /**
     Disables the UI so the user cannot interact with it.
     Also shows a spinner to indicate that we're busy.
     */
    @MainActor public func setUIBusy() {
        // If it takes more than 0.5s to set the UI to not busy, show a spinner
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            Task {
                @MainActor in self.progressIndicator.startAnimation(true)
            }
        })

        tableView.alphaValue = 0.3
        tableView.isEnabled = false
        tableView.selectRowIndexes([], byExtendingSelection: true)
    }

    /**
     Re-enables the UI so the user can interact with it.
     */
    @MainActor public func setUINotBusy() {
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
    internal func waitAndExecute(_ execute: @escaping () async -> Void, completion: @escaping () -> Void = {}) {
        Task { // Legacy `waitAndExecute` with UI
            setUIBusy()
            await execute()

            Task { @MainActor in
                await delay(seconds: 0.2)
                completion()
                setUINotBusy()
            }
        }
    }

    // MARK: - Site Data Loading

    func reloadDomains() async {
        waitAndExecute {
            await Valet.shared.reloadSites()
        } completion: { [self] in
            domains = Valet.shared.sites
            searchedFor(text: lastSearchedFor)
        }
    }

    func reloadDomainsWithoutUI() async {
        await Valet.shared.reloadSites()
        domains = Valet.shared.sites
        searchedFor(text: lastSearchedFor)
    }

    func applySortDescriptor(_ descriptor: NSSortDescriptor) {
        sortDescriptor = descriptor

        var sorted = self.domains

        switch descriptor.key {
        case "Secure": sorted = self.domains.sorted { $0.getListableSecured() && !$1.getListableSecured() }
        case "Domain": sorted = self.domains.sorted { $0.getListableName() < $1.getListableName() }
        case "PHP": sorted = self.domains.sorted { $0.getListablePhpVersion() < $1.getListablePhpVersion() }
        case "Kind": sorted = self.domains.sorted { $0.getListableKind() < $1.getListableKind() }
        case "Type": sorted = self.domains.sorted { $0.getListableType() < $1.getListableType() }
        default: break
        }

        self.domains = descriptor.ascending ? sorted.reversed() : sorted
    }

    func addedNewSite(name: String, secureAfterLinking: Bool) async {
        waitAndExecute {
            await Valet.shared.reloadSites()
        } completion: { [self] in
            find(name, secureAfterLinking)
        }
    }

    private func find(_ name: String, _ shouldSecure: Bool = false) {
        domains = Valet.getDomainListable()
        searchedFor(text: "")
        if let site = domains.enumerated().first(where: { $0.element.getListableName() == name }) {
            Task { @MainActor in
                self.tableView.selectRowIndexes([site.offset], byExtendingSelection: false)
                self.tableView.scrollRowToVisible(site.offset)
                if shouldSecure && !site.element.getListableSecured() {
                    self.toggleSecure()
                }
            }
        }
    }

    // MARK: - Table View Delegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return domains.count
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

        if let site = domains[row] as? ValetSite {
            userCell.populateCell(with: site)
        }

        if let proxy = domains[row] as? ValetProxy {
            userCell.populateCell(with: proxy)
        }

        return userCell as? NSView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        reloadContextMenu()
    }

    @objc func doubleClicked(sender: Any) {
        guard self.selected != nil else {
            return
        }

        self.openInBrowser()
    }

    // MARK: - (Search) Text Field Delegate

    func reloadTable() {
        if let sortDescriptor = sortDescriptor {
            self.applySortDescriptor(sortDescriptor)
        }

        Task { @MainActor in
            self.tableView.reloadData()
        }
    }

    func searchedFor(text: String) {
        lastSearchedFor = text

        let searchString = text.lowercased()

        if searchString.isEmpty {
            domains = Valet.getDomainListable()

            reloadTable()

            return
        }

        let splitSearchString: [String] = searchString
            .split(separator: " ")
            .map { return String($0) }

        domains = Valet.getDomainListable().filter({ site in
            return !splitSearchString.map { searchString in
                return site.getListableName().lowercased().contains(searchString)
            }.contains(false)
        })

        reloadTable()
    }

    // MARK: - Deinitialization

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }
}
