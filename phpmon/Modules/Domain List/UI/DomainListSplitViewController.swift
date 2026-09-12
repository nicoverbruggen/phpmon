//
//  DomainListSplitViewController.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class DomainListSplitViewController: NSSplitViewController {
    let domainListVC = DomainListVC()
    private var sidebarCollapseObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let sidebar = NSHostingController(rootView: DomainListSidebarView(
            model: domainListVC.sidebarModel,
            onSelect: { [weak self] filter in
                self?.domainListVC.selectFilter(filter)
            }
        ))
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 320
        sidebarItem.preferredThicknessFraction = 0.25
        sidebarItem.canCollapse = true
        sidebarItem.titlebarSeparatorStyle = .none
        addSplitViewItem(sidebarItem)

        let contentItem = NSSplitViewItem(viewController: domainListVC)
        contentItem.minimumThickness = 620
        contentItem.titlebarSeparatorStyle = .automatic
        addSplitViewItem(contentItem)

        // Test configurations must not read or change the user's window state.
        if !(App.shared.container.filesystem is TestableFileSystem) {
            sidebarItem.isCollapsed = UserDefaults.standard.bool(
                forKey: PersistentAppState.domainListSidebarCollapsed.rawValue
            )
            sidebarCollapseObservation = sidebarItem.observe(\.isCollapsed, options: [.new]) { _, change in
                guard let collapsed = change.newValue else { return }
                UserDefaults.standard.set(collapsed, forKey: PersistentAppState.domainListSidebarCollapsed.rawValue)
            }
        }
    }
}
