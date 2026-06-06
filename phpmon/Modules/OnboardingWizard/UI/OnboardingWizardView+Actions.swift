//
//  OnboardingWizardView+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension OnboardingWizardView {
    var bottomBar: some View {
        HStack {
            if let learnMoreLink = viewState.learnMoreLink {
                Button("onboarding_wizard.buttons.learn_more".localized) {
                    NSWorkspace.shared.open(learnMoreLink)
                }
                .buttonStyle(.link)
                .controlSize(.small)
            }

            if viewState.showsSkipValetButton {
                skipValetButton
            }

            Spacer()

            primaryActionButton
        }
    }

    var quitButton: some View {
        Button {
            viewModel.requestSkipConfirmation()
        } label: {
            Text("onboarding_wizard.buttons.skip".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .disabled(viewState.isRunning)
    }

    var skipValetButton: some View {
        Button {
            viewModel.requestSkipValetConfirmation()
        } label: {
            Text("onboarding_wizard.buttons.skip_valet".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .disabled(viewState.isRunning)
    }

    var primaryActionButton: some View {
        Button(primaryButtonTitle) {
            performPrimaryAction()
        }
        .focused($focusedButton, equals: .primary)
        .disabled(primaryButtonDisabled)
        .keyboardShortcut(.defaultAction)
    }

    func performPrimaryAction() {
        viewModel.performPrimaryAction()
    }
}
