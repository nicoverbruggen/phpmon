//
//  DomainListSidebarModel.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Combine
import Foundation

enum DomainListFilter: CaseIterable {
    case all, favorites, http, https, linked, parked, proxy, global, isolated

    func matches(_ domain: any ValetListable) -> Bool {
        switch self {
        case .all: return true
        case .favorites: return domain.getListableFavorited()
        case .http: return !domain.getListableSecured()
        case .https: return domain.getListableSecured()
        case .linked: return (domain as? ValetSite)?.aliasPath != nil
        case .parked:
            return (domain as? ValetSite).map { $0.aliasPath == nil } ?? false
        case .proxy: return domain is ValetProxy
        case .global:
            return (domain as? ValetSite).map { $0.isolatedPhpVersion == nil } ?? false
        case .isolated: return (domain as? ValetSite)?.isolatedPhpVersion != nil
        }
    }
}

class DomainListSidebarModel: ObservableObject {
    @Published var selection: DomainListFilter = .all
    @Published private(set) var counts: [DomainListFilter: Int] = [:]
    @Published var isBusy = false

    /// Counts describe the whole domain list, independent of the current search and selection.
    func updateCounts(from domains: [any ValetListable]) {
        counts = Dictionary(uniqueKeysWithValues: DomainListFilter.allCases.map { filter in
            (filter, domains.filter { filter.matches($0) }.count)
        })
    }

    func filteredDomains(from domains: [any ValetListable], search: String) -> [any ValetListable] {
        let terms = search.lowercased().split(separator: " ")
        return domains.filter { domain in
            selection.matches(domain) && terms.allSatisfy {
                domain.getListableName().lowercased().contains($0)
            }
        }
    }
}
