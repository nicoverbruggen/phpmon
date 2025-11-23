//
//  DomainListVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Carbon
import SwiftUI
import NVAlert

class DomainListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var container: Container {
        return App.shared.container
    }

    // MARK: - Outlets

    @IBOutlet weak var tableView: PMTableView!
    @IBOutlet weak var noResultsView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressIndicatorContainer: NSVisualEffectView!
    @IBOutlet weak var labelProgressIndicator: NSTextField!

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

    /// Set to true if we already checked for expired certificates.
    /// This prevents notifications about expired certificates from
    /// popping up when we re-open the Domains window.
    var didCheckForCertRenewal: Bool = false

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

    /// Timer used to determine whether this window has been busy
    /// for a certain amount of time.
    var timer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        tableView.doubleAction = #selector(self.doubleClicked(sender:))

        addNoResultsView()

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
            reloadDomainListables()
            searchedFor(text: lastSearchedFor)
        } else {
            Task { await reloadDomains() }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        if !didCheckForCertRenewal {
            checkForCertificateRenewal()
            didCheckForCertRenewal = true
        }
    }

    private func reloadDomainListables() {
        domains = Valet.getDomainListable()
    }

    private func addNoResultsView() {
        let child = NSHostingController(
            rootView: UnavailableContentView(
                title: "domain_list.domains_empty.title".localized,
                description: "domain_list.domains_empty.desc".localized,
                icon: "globe",
                button: "domain_list.domains_empty.button".localized,
                action: {
                    App.shared.domainListWindowController?
                        .pressedAddLink(nil)
                }
            )
            .frame(width: 400, height: 300)
        ).view

        self.noResultsView.addSubview(child)
        child.frame = self.noResultsView.bounds
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
                self.labelProgressIndicator.stringValue = "phpman.steps.wait".localized
                self.progressIndicatorContainer.layer?.cornerRadius = 10
                self.progressIndicatorContainer.isHidden = false
            }
        })

        tableView.alphaValue = 0.3
        tableView.isEnabled = false
        tableView.selectRowIndexes([], byExtendingSelection: true)
        noResultsView.isHidden = true
    }

    /**
     Re-enables the UI so the user can interact with it.
     */
    @MainActor public func setUINotBusy() {
        timer?.invalidate()
        progressIndicatorContainer.isHidden = true
        progressIndicator.stopAnimation(nil)
        tableView.alphaValue = 1.0
        tableView.isEnabled = true
        updateNoResultsView()
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
            reloadDomainListables()
            searchedFor(text: lastSearchedFor)
        }
    }

    func reloadDomainsWithoutUI() async {
        await Valet.shared.reloadSites()
        reloadDomainListables()
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

        sorted = descriptor.ascending ? sorted.reversed() : sorted

        self.domains = sorted.sorted { $0.getListableFavorited() && !$1.getListableFavorited() }
    }

    func addedNewSite(name: String, secureAfterLinking: Bool) async {
        waitAndExecute {
            await Valet.shared.reloadSites()
        } completion: { [self] in
            find(name, secureAfterLinking)
        }
    }

    private func find(_ name: String, _ shouldSecure: Bool = false) {
        reloadDomainListables()
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
        let mapping: [String: DomainListCellProtocol.Type] = [
            "TLS": DomainListTLSCell.self,
            "DOMAIN": DomainListNameCell.self,
            "ENVIRONMENT": DomainListPhpCell.self,
            "KIND": DomainListKindCell.self,
            "TYPE": DomainListTypeCell.self
        ]

        let columnName = tableColumn!.identifier.rawValue
        guard let cellType = mapping[columnName] else { return nil }
        let identifier = NSUserInterfaceItemIdentifier(rawValue: cellType.getCellIdentifier(for: domains[row]))

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
            updateNoResultsView()
        }
    }

    func updateNoResultsView() {
        self.noResultsView.isHidden = !domains.isEmpty
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
