//
//  DomainListVC+Window.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {
    enum CertificateRenewalPromptBehavior {
        case automatic
        case suppressed
    }

    // MARK: - Display

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = DomainListWindowController()
        windowController.shouldCascadeWindows = false

        let window = NSWindow()
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.titlebarSeparatorStyle = .line
        window.contentViewController = DomainListVC()
        windowController.window = window

        window.title = "domain_list.title".localized
        window.subtitle = ""
        window.delegate = delegate ?? windowController
        window.minSize = NSSize(width: 550, height: 200)

        windowController.configureToolbar()

        // Note: the autosave string stores the window's *content* rect; saving
        // and restoring are symmetric, so this can safely happen at creation.
        window.setFrameAutosaveName("domainListWindow")

        WindowManager.setController(windowController)
    }

    public static func show(
        delegate: NSWindowDelegate? = nil,
        certificateRenewalPrompt: CertificateRenewalPromptBehavior = .automatic
    ) {
        if !WindowManager.hasController(for: DomainListWC.self) {
            Self.create(delegate: delegate)
        }

        if case .suppressed = certificateRenewalPrompt {
            WindowManager
                .controller(of: DomainListWC.self)?
                .contentVC
                .shouldSkipAutomaticCertificateRenewalPrompt = true
        }

        WindowManager.show(DomainListWC.self)
    }
}
