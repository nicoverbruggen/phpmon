//
//  OnboardingWizardView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingWizardView: View {
    enum FocusedButton {
        case primary
    }

    @ObservedObject var viewModel: OnboardingWizardViewModel
    @State var isShowingSkipConfirmation = false
    @State var isShowingSkipValetConfirmation = false
    @FocusState var focusedButton: FocusedButton?

    let windowWidth: CGFloat = 720
    let windowHeight: CGFloat = 500
    let totalWizardSteps = 5

    init(
        viewModel: OnboardingWizardViewModel,
        isShowingSkipConfirmation: Bool = false,
        isShowingSkipValetConfirmation: Bool = false
    ) {
        self.viewModel = viewModel
        self._isShowingSkipConfirmation = State(initialValue: isShowingSkipConfirmation)
        self._isShowingSkipValetConfirmation = State(initialValue: isShowingSkipValetConfirmation)
    }

    var body: some View {
        wizardLayout
        .frame(width: windowWidth, height: windowHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(
            "onboarding_wizard.skip_confirmation.title".localized,
            isPresented: $isShowingSkipConfirmation
        ) {
            Button("onboarding_wizard.skip_confirmation.cancel".localized, role: .cancel) { }
            Button("onboarding_wizard.skip_confirmation.confirm".localized) {
                viewModel.skip()
            }
        } message: {
            Text("onboarding_wizard.skip_confirmation.message".localized)
        }
        .alert(
            "onboarding_wizard.skip_valet_confirmation.title".localized,
            isPresented: $isShowingSkipValetConfirmation
        ) {
            Button("onboarding_wizard.skip_valet_confirmation.cancel".localized, role: .cancel) { }
            Button("onboarding_wizard.skip_valet_confirmation.confirm".localized) {
                viewModel.skipValetSetup()
            }
        } message: {
            Text("onboarding_wizard.skip_valet_confirmation.message".localized)
        }
        .task {
            focusedButton = .primary
            await viewModel.loadIfNeeded()
            focusedButton = .primary
        }
        .onChange(of: primaryButtonDisabled) { isDisabled in
            if !isDisabled {
                focusedButton = .primary
            }
        }
        .onChange(of: viewModel.state) { _ in
            focusedButton = .primary
        }
        .onChange(of: viewModel.currentStep) { _ in
            focusedButton = .primary
        }
    }

    var isShowingIntroduction: Bool {
        return viewModel.currentStep == .introduction
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
        .padding(.top, 20)
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
