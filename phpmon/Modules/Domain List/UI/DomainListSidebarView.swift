//
//  DomainListSidebarView.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct DomainListSidebarView: View {
    @ObservedObject var model: DomainListSidebarModel
    let onSelect: (DomainListFilter) -> Void

    @State private var securedExpanded = true
    @State private var kindExpanded = true
    @State private var phpExpanded = true

    var body: some View {
        List(selection: Binding<DomainListFilter?>(
            get: { model.selection },
            set: { if let filter = $0 { onSelect(filter) } }
        )) {
            row("All domains", filter: .all, symbol: "globe")
            row("Favorites", filter: .favorites, symbol: "star")
            sidebarSection("Secured", isExpanded: $securedExpanded) {
                row("HTTP", filter: .http, symbol: "lock.open")
                row("HTTPS", filter: .https, symbol: "lock")
            }
            sidebarSection("Kind", isExpanded: $kindExpanded) {
                row("Linked", filter: .linked, asset: "IconLinked")
                row("Parked", filter: .parked, asset: "IconParked")
                row("Proxy", filter: .proxy, asset: "IconProxy")
            }
            sidebarSection("PHP", isExpanded: $phpExpanded) {
                row("Global", filter: .global, symbol: "globe")
                row("Isolated", filter: .isolated, asset: "Isolated")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .disabled(model.isBusy)
    }

    @ViewBuilder
    private func sidebarSection<Content: View>(
        _ title: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(macOS 14.0, *) {
            Section(title, isExpanded: isExpanded, content: content)
        } else {
            DisclosureGroup(title, isExpanded: isExpanded, content: content)
        }
    }

    private func row(
        _ title: String, filter: DomainListFilter, symbol: String? = nil, asset: String? = nil
    ) -> some View {
        Label {
            HStack {
                Text(title)
                    .fontWeight(model.selection == filter ? .semibold : .regular)
                Spacer(minLength: 8)
                Text(model.counts[filter, default: 0].formatted())
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        model.selection == filter
                            ? Color.white.opacity(0.2)
                            : Color(nsColor: .controlBackgroundColor).opacity(0.6),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule().strokeBorder(
                            model.selection == filter
                                ? Color.white.opacity(0.35)
                                : Color(nsColor: .separatorColor),
                            lineWidth: 0.5
                        )
                    }
                    .accessibilityLabel("\(model.counts[filter, default: 0]) domains")
            }
        } icon: {
            if let asset {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            } else if let symbol {
                Image(systemName: symbol)
            }
        }
        .tag(filter)
    }
}
