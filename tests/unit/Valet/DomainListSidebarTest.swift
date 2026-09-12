//
//  DomainListSidebarTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

struct DomainListSidebarTest {
    private func fixtures() -> (sites: [ValetSite], proxy: ValetProxy) {
        let container = Container.fake(shell: [
            "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
        ])
        let sites = ["alpha-api", "beta-web", "gamma-api"].map { name in
            ValetSite(container, name: name, tld: "test", absolutePath: "/sites/\(name)",
                      makeDeterminations: false)
        }
        sites[0].aliasPath = "/links/alpha-api"
        sites[0].favorited = true
        sites[1].secured = true
        sites[2].aliasPath = "/links/gamma-api"
        sites[2].secured = true
        sites[2].favorited = true
        sites[2].isolatedPhpVersion = PhpInstallation(container, "8.4", probe: .init(container, "8.4"))

        let proxy = ValetProxy(container, domain: "proxy-api", target: "http://localhost:3000",
                               secure: false, tld: "test")
        proxy.favorited = true
        return (sites, proxy)
    }

    @Test func filters_match_domain_metadata_and_exclude_proxies_from_php() {
        let (sites, proxy) = fixtures()
        let domains: [any ValetListable] = sites + [proxy]
        let model = DomainListSidebarModel()
        let expected: [DomainListFilter: [String]] = [
            .all: ["alpha-api", "beta-web", "gamma-api", "proxy-api"],
            .favorites: ["alpha-api", "gamma-api", "proxy-api"],
            .http: ["alpha-api", "proxy-api"],
            .https: ["beta-web", "gamma-api"],
            .linked: ["alpha-api", "gamma-api"],
            .parked: ["beta-web"],
            .proxy: ["proxy-api"],
            .global: ["alpha-api", "beta-web"],
            .isolated: ["gamma-api"]
        ]

        model.updateCounts(from: domains)
        for filter in DomainListFilter.allCases {
            model.selection = filter
            #expect(model.filteredDomains(from: domains, search: "").map { $0.getListableName() } == expected[filter])
            #expect(model.counts[filter] == expected[filter]?.count)
        }
    }

    @Test func search_intersects_filter_without_changing_totals() {
        let (sites, proxy) = fixtures()
        let domains: [any ValetListable] = sites + [proxy]
        let model = DomainListSidebarModel()
        model.selection = .https
        model.updateCounts(from: domains)

        #expect(model.filteredDomains(from: domains, search: "  API GAMMA  ").map {
            $0.getListableName()
        } == ["gamma-api"])
        #expect(model.filteredDomains(from: domains, search: "alpha").isEmpty)
        #expect(model.counts[.https] == 2)
        #expect(model.counts[.all] == 4)
        #expect(model.filteredDomains(from: domains, search: "  ").count == 2)
    }

    @Test func metadata_changes_and_removals_refresh_counts_and_visible_rows() {
        let (sites, proxy) = fixtures()
        let domains: [any ValetListable] = sites + [proxy]
        let controller = DomainListVC()
        controller.sidebarModel.selection = .favorites
        controller.lastSearchedFor = "api"
        controller.updateDomains(from: domains)
        #expect(controller.domains.count == 3)

        sites[0].favorited = false
        sites[0].secured = true
        sites[2].isolatedPhpVersion = nil
        proxy.secured = true
        controller.updateDomains(from: domains)

        #expect(controller.domains.map { $0.getListableName() } == ["gamma-api", "proxy-api"])
        #expect(controller.sidebarModel.counts[.favorites] == 2)
        #expect(controller.sidebarModel.counts[.http] == 0)
        #expect(controller.sidebarModel.counts[.https] == 4)
        #expect(controller.sidebarModel.counts[.isolated] == 0)
        #expect(controller.sidebarModel.counts[.global] == 3)

        controller.updateDomains(from: [])
        #expect(controller.domains.isEmpty)
        #expect(controller.sidebarModel.selection == .favorites)
        #expect(controller.lastSearchedFor == "api")
        #expect(controller.sidebarModel.counts.values.allSatisfy { $0 == 0 })
    }

    @Test func sorting_keeps_the_selected_domain_when_its_row_moves() {
        let (sites, proxy) = fixtures()
        let controller = DomainListVC()
        let dataSource = SidebarTableDataSource(controller)
        controller.tableView.dataSource = dataSource
        defer { withExtendedLifetime(dataSource) {} }
        controller.updateDomains(from: sites + [proxy])
        controller.tableView.selectRowIndexes([0], byExtendingSelection: false)
        #expect(controller.selectedSite?.name == "alpha-api")

        controller.tableView.sortDescriptors = [NSSortDescriptor(key: "Domain", ascending: true)]
        controller.tableView(controller.tableView, sortDescriptorsDidChange: [])

        #expect(controller.tableView.selectedRow == 2)
        #expect(controller.selectedSite?.name == "alpha-api")
    }

    @Test func filtering_preserves_sort_and_selection_without_retargeting_removed_rows() {
        let (sites, proxy) = fixtures()
        let domains: [any ValetListable] = sites + [proxy]
        let controller = DomainListVC()
        let dataSource = SidebarTableDataSource(controller)
        controller.tableView.dataSource = dataSource
        defer { withExtendedLifetime(dataSource) {} }
        controller.tableView.sortDescriptors = [NSSortDescriptor(key: "Domain", ascending: false)]
        controller.updateDomains(from: domains)
        controller.tableView.selectRowIndexes([1], byExtendingSelection: false)
        #expect(controller.selectedSite?.name == "gamma-api")

        controller.sidebarModel.selection = .https
        controller.updateDomains(from: domains)
        #expect(controller.domains.map { $0.getListableName() } == ["gamma-api", "beta-web"])
        #expect(controller.selectedSite?.name == "gamma-api")
        #expect(controller.tableView.selectedRow == 0)

        controller.sidebarModel.selection = .parked
        controller.updateDomains(from: domains)
        #expect(controller.selected == nil)
        #expect(controller.tableView.selectedRow == -1)
        #expect(controller.domains.map { $0.getListableName() } == ["beta-web"])
    }
}

/// Supply rows without asking NSViewController to load the app's view hierarchy.
private class SidebarTableDataSource: NSObject, NSTableViewDataSource {
    let controller: DomainListVC

    init(_ controller: DomainListVC) {
        self.controller = controller
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        controller.domains.count
    }
}
