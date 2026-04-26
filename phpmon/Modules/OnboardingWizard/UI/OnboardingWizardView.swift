//
//  OnboardingWizardView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingWizardView: View {
    @ObservedObject var viewModel: OnboardingWizardViewModel
    @State var hasStartedWizard = false
    @State var isShowingQuitConfirmation = false
    @State var displayedStepNumber: Int?

    let windowWidth: CGFloat = 720
    let windowHeight: CGFloat = 500
    let totalWizardSteps = 5

    init(
        viewModel: OnboardingWizardViewModel,
        hasStartedWizard: Bool = false,
        isShowingQuitConfirmation: Bool = false,
        displayedStepNumber: Int? = nil
    ) {
        self.viewModel = viewModel
        self._hasStartedWizard = State(initialValue: hasStartedWizard)
        self._isShowingQuitConfirmation = State(initialValue: isShowingQuitConfirmation)
        self._displayedStepNumber = State(initialValue: displayedStepNumber)
    }

    var body: some View {
        wizardLayout
        .frame(width: windowWidth, height: windowHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(
            "onboarding_wizard.quit_confirmation.title".localized,
            isPresented: $isShowingQuitConfirmation
        ) {
            Button("onboarding_wizard.quit_confirmation.cancel".localized, role: .cancel) { }
            Button("onboarding_wizard.quit_confirmation.confirm".localized, role: .destructive) {
                viewModel.quit()
            }
        } message: {
            Text("onboarding_wizard.quit_confirmation.message".localized)
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    var isShowingIntroduction: Bool {
        return !hasStartedWizard
            && viewModel.state == .idle
            && !viewModel.showsOutput
    }

    var wizardLayout: some View {
        HStack(spacing: 0) {
            sidebar

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.45))
                .frame(width: 1)

            wizardMain
        }
    }

    var wizardMain: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isShowingIntroduction {
                introductionContent
            } else {
                stepContent
            }

            Spacer(minLength: 16)

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.45))
                .frame(height: 1)
                .padding(.bottom, 14)

            bottomBar
        }
        .padding(.top, 28)
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
