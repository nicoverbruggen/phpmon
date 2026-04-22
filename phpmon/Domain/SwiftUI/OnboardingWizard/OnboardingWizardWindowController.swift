//
//  OnboardingWizardWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class OnboardingWizardWindowController: PMWindowController {

    override var windowName: String {
        return "OnboardingWizard"
    }

    private var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?
    private var didResolve = false

    static func create() -> OnboardingWizardWindowController {
        let windowController = OnboardingWizardWindowController()
        let window = NSWindow()

        window.title = ""
        window.styleMask = [.titled, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = windowController
        window.contentView = NSHostingView(rootView: OnboardingWizardView(
            onContinue: {
                windowController.complete(with: .completed)
            },
            onQuit: {
                windowController.complete(with: .quit)
            }
        ))
        window.setContentSize(window.contentView!.fittingSize)
        window.isReleasedWhenClosed = false

        windowController.window = window
        return windowController
    }

    @MainActor
    func showModal() async -> Startup.OnboardingWizardOutcome {
        return await withCheckedContinuation { continuation in
            self.onComplete = { [weak self] outcome in
                guard let self, !self.didResolve else { return }
                self.didResolve = true
                self.close()
                continuation.resume(returning: outcome)
            }

            self.showWindow(nil)
            self.window?.setCenterPosition(offsetY: 70)
            NSApp.activate(ignoringOtherApps: true)
            self.window?.orderFrontRegardless()
        }
    }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)

        if !didResolve {
            exit(1)
        }
    }

    private func complete(with outcome: Startup.OnboardingWizardOutcome) {
        onComplete?(outcome)
    }
}
