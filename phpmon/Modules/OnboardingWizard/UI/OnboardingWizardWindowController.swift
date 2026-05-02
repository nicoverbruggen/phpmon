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
    private var hiddenMenuItems: [NSMenuItem] = []
    private var alertObservationTask: Task<Void, Never>?

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
        window.contentView = NSHostingView(rootView: OnboardingWizardView(viewModel: viewModel))
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
            let alertStream = viewModel.observeAlerts()

            self.alertObservationTask = Task { [weak self] in
                for await alertState in alertStream {
                    guard !Task.isCancelled else {
                        break
                    }

                    await MainActor.run {
                        guard let self else {
                            return
                        }

                        switch alertState {
                        case .developerToolsIncomplete:
                            self.viewModel?.dismissAlert()
                            self.presentDeveloperToolsIncompleteAlert()
                        case .valetSudoersCleanupFailed(let command):
                            self.viewModel?.dismissAlert()
                            self.presentValetSudoersRemovalFailedAlert(command: command)
                        case .skipConfirmation, .skipValetConfirmation:
                            break
                        }
                    }
                }
            }

            self.hideMenuItems()
            self.showWindow(nil)
            self.window?.setCenterPosition(offsetY: 70)
            NSApp.activate(ignoringOtherApps: true)
            self.window?.orderFrontRegardless()
        }
    }

    private func hideMenuItems() {
        guard let mainMenu = NSApp.mainMenu, hiddenMenuItems.isEmpty else { return }
        // Index 0 is the application menu ("PHP Monitor" → About/Quit) — leave it
        // available so the user can still quit while the wizard is up.
        hiddenMenuItems = Array(mainMenu.items.dropFirst())
        hiddenMenuItems.forEach { $0.isHidden = true }
    }

    private func restoreMenuItems() {
        hiddenMenuItems.forEach { $0.isHidden = false }
        hiddenMenuItems = []
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
        alertObservationTask?.cancel()
        alertObservationTask = nil
        restoreMenuItems()
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

    @MainActor private func presentValetSudoersRemovalFailedAlert(command: String) {
        guard let window else {
            return
        }

        NVAlert()
            .withInformation(
                title: "onboarding_wizard.alert.valet_sudoers_cleanup_failed.title".localized,
                subtitle: "onboarding_wizard.alert.valet_sudoers_cleanup_failed.subtitle".localized,
                description: "onboarding_wizard.alert.valet_sudoers_cleanup_failed.description".localized(
                    command
                )
            )
            .withPrimary(text: "generic.ok".localized)
            .withSecondary(text: "onboarding_wizard.alert.valet_sudoers_cleanup_failed.copy_command".localized) { alert in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    command,
                    forType: .string
                )
                alert.close(with: .alertSecondButtonReturn)
            }
            .presentAsSheet(attachedTo: window)
    }
}
