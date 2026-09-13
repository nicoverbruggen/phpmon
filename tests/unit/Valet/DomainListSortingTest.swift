//
//  DomainListSortingTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import AppKit

struct DomainListSortingTest {
    @Test func restored_column_order_is_used_when_reloading_domains() {
        let container = Container.fake()
        let sites = ["charlie", "bravo", "alpha"].map { name in
            ValetSite(container, name: name, tld: "test", absolutePath: "/sites/\(name)",
                      aliasPath: nil, makeDeterminations: false)
        }
        sites[1].favorited = true

        let controller = DomainListVC()
        // AppKit restores these before the programmatic table's delegate is connected.
        controller.tableView.sortDescriptors = [NSSortDescriptor(key: "Domain", ascending: false)]
        controller.domains = sites
        controller.reloadTable()

        #expect(controller.domains.map { $0.getListableName() } == ["bravo", "alpha", "charlie"])
    }

    @Test func favorites_stay_first_without_a_column_sort() {
        let container = Container.fake()
        let sites = ["alpha", "bravo", "charlie", "delta"].map { name in
            ValetSite(container, name: name, tld: "test", absolutePath: "/sites/\(name)",
                      aliasPath: nil, makeDeterminations: false)
        }
        sites[1].favorited = true
        sites[3].favorited = true

        let controller = DomainListVC()
        controller.domains = sites
        controller.reloadTable()

        #expect(controller.domains.map { $0.getListableName() } == ["bravo", "delta", "alpha", "charlie"])

        sites[1].favorited = false
        controller.reloadTable()

        #expect(controller.domains.map { $0.getListableName() } == ["delta", "bravo", "alpha", "charlie"])
    }
}
