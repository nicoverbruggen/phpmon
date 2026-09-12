//
//  DomainListVC+Sidebar.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {
    func selectFilter(_ filter: DomainListFilter) {
        guard !sidebarModel.isBusy else { return }
        sidebarModel.selection = filter
        searchedFor(text: lastSearchedFor)
    }

    func updateDomains(from allDomains: [any ValetListable]) {
        let selection = selectedIdentity
        // Clear the old row before replacing the data used by selection callbacks.
        tableView.deselectAll(nil)
        sidebarModel.updateCounts(from: allDomains)
        domains = sidebarModel.filteredDomains(from: allDomains, search: lastSearchedFor)
        reloadTable()
        restoreSelection(selection)
    }

    var selectedIdentity: String? {
        selected.map { identity(for: $0) }
    }

    func restoreSelection(_ identity: String?) {
        guard let identity,
              let row = domains.firstIndex(where: { self.identity(for: $0) == identity }) else { return }
        tableView.selectRowIndexes([row], byExtendingSelection: false)
    }

    private func identity(for domain: any ValetListable) -> String {
        if let site = domain as? ValetSite { return site.favoriteSignature }
        if let proxy = domain as? ValetProxy { return proxy.favoriteSignature }
        return "\(domain.getListableName()).\(domain.getListableTLD())|\(domain.getListableAbsolutePath())"
    }
}
