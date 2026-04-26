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
            if showsSkipValetButton {
                skipValetButton
            }

            Spacer()

            primaryActionButton
        }
    }

    var quitButton: some View {
        Button {
            isShowingSkipConfirmation = true
        } label: {
            Text("onboarding_wizard.buttons.skip".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
    }

    var skipValetButton: some View {
        Button {
            isShowingSkipValetConfirmation = true
        } label: {
            Text("onboarding_wizard.buttons.skip_valet".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.state == .running)
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
        if isShowingIntroduction {
            hasDismissedIntroduction = true
            displayedStepNumber = 1
        } else if isDisplayingCompletedStep {
            advanceDisplayedStep()
        } else {
            viewModel.performPrimaryAction()
        }
    }

    func advanceDisplayedStep() {
        viewModel.clearOutput()
        displayedStepNumber = nil
    }

    var showsSkipValetButton: Bool {
        !isShowingIntroduction
            && !isDisplayingCompletedStep
            && viewModel.action == .installValet
    }
}
