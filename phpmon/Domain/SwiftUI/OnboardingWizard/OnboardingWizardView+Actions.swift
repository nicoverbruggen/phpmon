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
            Spacer()

            primaryActionButton
        }
    }

    var quitButton: some View {
        Button("onboarding_wizard.buttons.quit".localized) {
            isShowingQuitConfirmation = true
        }
        .keyboardShortcut(.cancelAction)
    }

    var primaryActionButton: some View {
        Button(primaryButtonTitle) {
            performPrimaryAction()
        }
        .disabled(primaryButtonDisabled)
        .keyboardShortcut(.defaultAction)
    }

    func performPrimaryAction() {
        if isShowingIntroduction {
            hasStartedWizard = true
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
}
