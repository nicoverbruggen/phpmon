//
//  OnboardingWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class OnboardingWC: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Onboarding"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        let windowController = storyboard.instantiateController(
            withIdentifier: "onboardingWindow"
        ) as! OnboardingWC

        windowController.window!.title = "onboarding.title".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [.titled, .closable, .miniaturizable]
        windowController.window!.delegate = windowController
        windowController.window!.contentView = NSHostingView(rootView: OnboardingView())
        windowController.window!.setContentSize(NSSize(width: 600, height: 600))

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
}
