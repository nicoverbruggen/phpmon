//
//  DomainListSidebarRenderingTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import SwiftUI
import Testing

struct DomainListSidebarRenderingTest {
    @Test func selection_publishes_after_the_native_list_update_finishes() async throws {
        let container = Container.fake()
        let site = ValetSite(container, name: "example", tld: "test", absolutePath: "/sites/example",
                             makeDeterminations: false)
        site.favorited = true
        let model = DomainListSidebarModel()
        var selectingRow = false
        var selections: [DomainListFilter] = []
        let host = NSHostingView(rootView: DomainListSidebarView(model: model, onSelect: { filter in
            #expect(!selectingRow, "The selection callback must not publish during the native list update.")
            selections.append(filter)
            model.selection = filter
            model.updateCounts(from: [site])
        }))
        // Attach the hosting view to a window without showing it or changing focus.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 260, height: 440),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        model.updateCounts(from: [site])
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        let table = try #require(findTable(in: host))
        #expect(table.numberOfRows >= 2)

        for (row, filter) in [(1, DomainListFilter.favorites), (0, DomainListFilter.all)] {
            selectingRow = true
            table.selectRowIndexes([row], byExtendingSelection: false)
            host.layoutSubtreeIfNeeded()
            selectingRow = false
            try await Task.sleep(for: .milliseconds(100))
            #expect(model.selection == filter)
        }
        #expect(selections == [.favorites, .all])
        #expect(model.counts[.favorites] == 1)
    }

    private func findTable(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        return view.subviews.lazy.compactMap { findTable(in: $0) }.first
    }
}
