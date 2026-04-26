//
//  OnboardingWizardWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAlert
import SwiftUI

class OnboardingWizardWindowController: PMWindowController {

    override var windowName: String {
        return "OnboardingWizard"
    }

    private var viewModel: OnboardingWizardViewModel?
    private var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?
    private var didResolve = false
    private var exitsApplicationOnClose = true

    static func create(
        exitsApplicationOnClose: Bool = true,
        flow: any OnboardingFlowDefinition = FullSetupOnboardingFlow()
    ) -> OnboardingWizardWindowController {
        let windowController = OnboardingWizardWindowController()
        windowController.exitsApplicationOnClose = exitsApplicationOnClose
        let viewModel = OnboardingWizardViewModel(flow: flow)
        windowController.viewModel = viewModel
        let window = NSWindow()

        window.title = ""
        window.styleMask = [.titled, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = windowController
        window.contentView = NSHostingView(rootView: OnboardingWizardView(
            viewModel: viewModel,
            entryMode: flow.entryMode
        ))
        window.setContentSize(window.contentView!.fittingSize)
        window.isReleasedWhenClosed = false

        windowController.window = window
        return windowController
    }

    @MainActor
    func showModal() async -> Startup.OnboardingWizardOutcome {
        return await withCheckedContinuation { continuation in
            guard let viewModel = self.viewModel else {
                continuation.resume(returning: .skipped)
                return
            }

            self.onComplete = { [weak self] outcome in
                guard let self, !self.didResolve else { return }
                self.didResolve = true
                self.close()
                continuation.resume(returning: outcome)
            }

            viewModel.onComplete = { [weak self] outcome in
                self?.complete(with: outcome)
            }
            viewModel.onDeveloperToolsRecheckFailed = { [weak self] in
                self?.presentDeveloperToolsIncompleteAlert()
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
            if exitsApplicationOnClose {
                exit(1)
            } else {
                complete(with: .skipped)
            }
        }
    }

    private func complete(with outcome: Startup.OnboardingWizardOutcome) {
        onComplete?(outcome)
    }

    @MainActor private func presentDeveloperToolsIncompleteAlert() {
        guard let window else {
            return
        }

        NVAlert()
            .withInformation(
                title: "onboarding_wizard.alert.developer_tools_incomplete.title".localized,
                subtitle: "onboarding_wizard.alert.developer_tools_incomplete.subtitle".localized,
                description: "onboarding_wizard.alert.developer_tools_incomplete.description".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .withSecondary(text: "onboarding_wizard.alert.developer_tools_incomplete.copy_command".localized) { alert in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("/usr/bin/xcode-select --install", forType: .string)
                alert.close(with: .alertSecondButtonReturn)
            }
            .presentAsSheet(attachedTo: window)
    }
}
