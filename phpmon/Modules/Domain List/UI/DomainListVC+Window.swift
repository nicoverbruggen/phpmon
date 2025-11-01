//
//  DomainListVC+Window.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {
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
}
