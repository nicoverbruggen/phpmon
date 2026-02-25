//
//  StartupAlertWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class StartupAlertWindowController: PMWindowController {

    override var windowName: String {
        return "StartupAlert"
    }

    private var viewModel: StartupAlertViewModel?
    private var didResolve = false

    static func create(for check: EnvironmentCheck) -> StartupAlertWindowController {
        let windowController = StartupAlertWindowController()
        let viewModel = StartupAlertViewModel(check: check)
        windowController.viewModel = viewModel

        let window = NSWindow()
        window.title = ""
        window.styleMask = [.titled, .closable]
        window.titlebarAppearsTransparent = true
        window.delegate = windowController
        window.contentView = NSHostingView(rootView: StartupAlertView(viewModel: viewModel))
        window.setContentSize(window.contentView!.fittingSize)
        window.isReleasedWhenClosed = false

        windowController.window = window
        return windowController
    }

    @MainActor
    func showModal() async -> Startup.EnvironmentAlertOutcome {
        return await withCheckedContinuation { continuation in
            guard let viewModel = self.viewModel else {
                continuation.resume(returning: .shouldRetryStartup)
                return
            }

            viewModel.onComplete = { [weak self] outcome in
                guard let self, !self.didResolve else { return }
                self.didResolve = true
                self.close()
                continuation.resume(returning: outcome)
            }

            self.showWindow(nil)
            self.window?.center()
            NSApp.activate(ignoringOtherApps: true)
            self.window?.orderFrontRegardless()
        }
    }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)

        // If closed via the close button without resolving, quit the app
        if !didResolve {
            exit(1)
        }
    }
}
