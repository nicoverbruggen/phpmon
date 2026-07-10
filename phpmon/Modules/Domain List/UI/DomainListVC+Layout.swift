//
//  DomainListVC+Layout.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {
    /**
     Builds the entire view hierarchy in code, transcribed from the old
     storyboard scene: the scroll view + table, the "no results" container
     and the busy overlay.
     */
    func makeRootView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 626, height: 309))

        configureTableView()

        // The scroll view hosting the table (fills the entire view)
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.usesPredominantAxisScrolling = false
        scrollView.verticalLineScroll = 54
        scrollView.horizontalLineScroll = 54
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        scrollView.documentView = tableView
        view.addSubview(scrollView)

        // The "no results" container (content is a hosted SwiftUI view)
        noResultsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noResultsView)

        // The busy overlay: a visual effect "card" with a spinner and label
        progressIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        progressIndicatorContainer.blendingMode = .behindWindow
        progressIndicatorContainer.material = .popover
        progressIndicatorContainer.state = .followsWindowActiveState
        progressIndicatorContainer.isHidden = true

        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .spinning
        progressIndicator.isIndeterminate = true
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicatorContainer.addSubview(progressIndicator)

        labelProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        labelProgressIndicator.font = NSFont.systemFont(ofSize: 10)
        labelProgressIndicator.textColor = .secondaryLabelColor
        labelProgressIndicator.lineBreakMode = .byClipping
        progressIndicatorContainer.addSubview(labelProgressIndicator)

        view.addSubview(progressIndicatorContainer)

        NSLayoutConstraint.activate([
            // Scroll view fills the view and must be at least 620×300
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 620),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),

            // No-results view: fixed 400×300, centered
            noResultsView.widthAnchor.constraint(equalToConstant: 400),
            noResultsView.heightAnchor.constraint(equalToConstant: 300),
            noResultsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Busy overlay: fixed 100×80 card, centered (10pt above center)
            progressIndicatorContainer.widthAnchor.constraint(equalToConstant: 100),
            progressIndicatorContainer.heightAnchor.constraint(equalToConstant: 80),
            progressIndicatorContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicatorContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),

            // Spinner and label within the card
            progressIndicator.widthAnchor.constraint(equalToConstant: 30),
            progressIndicator.heightAnchor.constraint(equalToConstant: 30),
            progressIndicator.centerXAnchor.constraint(equalTo: progressIndicatorContainer.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(
                equalTo: progressIndicatorContainer.centerYAnchor, constant: -10
            ),
            labelProgressIndicator.centerXAnchor.constraint(equalTo: progressIndicatorContainer.centerXAnchor),
            labelProgressIndicator.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 8)
        ])

        return view
    }

    /**
     Configures the table: 5 columns with the same identifiers, widths, sort
     keys and header alignments as the old storyboard prototypes.
     */
    private func configureTableView() {
        tableView.rowHeight = 54
        tableView.intercellSpacing = NSSize(width: 17, height: 0)
        tableView.backgroundColor = .controlBackgroundColor
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        tableView.gridColor = .quaternaryLabelColor
        tableView.allowsMultipleSelection = false
        tableView.allowsExpansionToolTips = true
        tableView.usesAutomaticRowHeights = false

        struct Column {
            let identifier: String
            let title: String
            let width: CGFloat
            let minWidth: CGFloat
            let maxWidth: CGFloat
            let sortKey: String
            let headerAlignment: NSTextAlignment
        }

        let columns: [Column] = [
            Column(identifier: "TLS", title: "TLS", width: 36, minWidth: 36, maxWidth: 36,
                   sortKey: "Secure", headerAlignment: .center),
            Column(identifier: "DOMAIN", title: "Domain", width: 200, minWidth: 200, maxWidth: 10000,
                   sortKey: "Domain", headerAlignment: .left),
            Column(identifier: "ENVIRONMENT", title: "Active", width: 100, minWidth: 100, maxWidth: 150,
                   sortKey: "PHP", headerAlignment: .center),
            Column(identifier: "KIND", title: "Kind", width: 50, minWidth: 50, maxWidth: 120,
                   sortKey: "Kind", headerAlignment: .natural),
            Column(identifier: "TYPE", title: "Project Type", width: 100, minWidth: 100, maxWidth: 100,
                   sortKey: "Type", headerAlignment: .center)
        ]

        for definition in columns {
            let column = NSTableColumn(
                identifier: NSUserInterfaceItemIdentifier(rawValue: definition.identifier)
            )
            column.title = definition.title
            column.width = definition.width
            column.minWidth = definition.minWidth
            column.maxWidth = definition.maxWidth
            column.resizingMask = [.autoresizingMask, .userResizingMask]
            column.sortDescriptorPrototype = NSSortDescriptor(key: definition.sortKey, ascending: true)
            column.headerCell.alignment = definition.headerAlignment
            tableView.addTableColumn(column)
        }

        // Setting the autosave name after the columns exist restores saved widths
        tableView.autosaveName = "phpmon-sitelist-columns"
        tableView.autosaveTableColumns = true

        tableView.delegate = self
        tableView.dataSource = self
    }
}
