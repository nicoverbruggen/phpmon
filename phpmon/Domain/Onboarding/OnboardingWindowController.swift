//
//  OnboardingWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/06/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class OnboardingWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Onboarding"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: OnboardingView())
        window.setContentSize(NSSize(width: 600, height: 600))

        App.shared.onboardingWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.onboardingWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.onboardingWindowController?.showWindow(self)
        App.shared.onboardingWindowController?.window?.setCenterPosition(offsetY: 70)

        NSApp.activate(ignoringOtherApps: true)
    }

    override func close() {
        super.close()

        // Search for updates after closing the window
        if Stats.successfulLaunchCount == 1 {
            Task { await AppUpdater().checkForUpdates(interactive: false) }
        }
    }
}
