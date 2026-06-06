//
//  WelcomeTourWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class WelcomeTourWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "WelcomeTour"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: WelcomeTourView())
        window.setContentSize(window.contentView!.fittingSize)

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: WelcomeTourWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(WelcomeTourWC.self)
        WindowManager.withWindow(for: WelcomeTourWC.self) { window in
            window.setCenterPosition(offsetY: 70)
        }
    }

    override func close() {
        super.close()

        // Search for updates after closing the window
        if Stats.successfulLaunchCount == 1 {
            Task { await AppUpdater().checkForUpdates(userInitiated: false) }
        }
    }
}
