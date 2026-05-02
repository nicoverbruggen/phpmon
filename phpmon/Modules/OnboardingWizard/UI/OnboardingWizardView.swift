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
    @FocusState var focusedButton: FocusedButton?

    let windowWidth: CGFloat = 720
    let windowHeight: CGFloat = 500

    init(
        viewModel: OnboardingWizardViewModel,
        isShowingSkipConfirmation: Bool = false,
        isShowingSkipValetConfirmation: Bool = false
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        wizardLayout
        .alert(
            "onboarding_wizard.skip_confirmation.title".localized,
            isPresented: skipConfirmationBinding
        ) {
            Button("onboarding_wizard.skip_confirmation.cancel".localized, role: .cancel) { }
            Button("onboarding_wizard.skip_confirmation.confirm".localized) {
                viewModel.confirmSkipCurrentAlert()
            }
        } message: {
            Text("onboarding_wizard.skip_confirmation.message".localized)
        }
        .alert(
            "onboarding_wizard.skip_valet_confirmation.title".localized,
            isPresented: skipValetConfirmationBinding
        ) {
            Button("onboarding_wizard.skip_valet_confirmation.cancel".localized, role: .cancel) { }
            Button("onboarding_wizard.skip_valet_confirmation.confirm".localized) {
                viewModel.confirmSkipCurrentAlert()
            }
        } message: {
            Text("onboarding_wizard.skip_valet_confirmation.message".localized)
        }
        .task {
            updateDefaultFocus()
            await viewModel.loadIfNeeded()
            updateDefaultFocus()
        }
        .onChange(of: viewModel.viewState.primaryButtonDisabled) { isDisabled in
            if !isDisabled {
                updateDefaultFocus()
            }
        }
        .onChange(of: viewModel.state) { _ in
            updateDefaultFocus()
        }
        .onChange(of: viewModel.currentStep) { _ in
            updateDefaultFocus()
        }
    }

    var viewState: OnboardingViewState {
        return viewModel.viewState
    }

    var skipConfirmationBinding: Binding<Bool> {
        Binding(
            get: {
                if case .skipConfirmation? = viewModel.alertState {
                    return true
                }

                return false
            },
            set: { isPresented in
                if !isPresented, case .skipConfirmation? = viewModel.alertState {
                    viewModel.dismissAlert()
                }
            }
        )
    }

    var skipValetConfirmationBinding: Binding<Bool> {
        Binding(
            get: {
                if case .skipValetConfirmation? = viewModel.alertState {
                    return true
                }

                return false
            },
            set: { isPresented in
                if !isPresented, case .skipValetConfirmation? = viewModel.alertState {
                    viewModel.dismissAlert()
                }
            }
        )
    }

    var wizardLayout: some View {
        HStack(spacing: 0) {
            sidebar

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.45))
                .frame(width: 1)

            wizardMain
        }
        .frame(width: windowWidth, height: windowHeight)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    var wizardMain: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewState.isShowingIntroduction {
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

    /**
     The default focus should always be updated to the primary action
     when the view's contents are being updated. This usually happens
     when a task has completed or we are moving to the next step in
     the onboarding flow's wizard.
     */
    func updateDefaultFocus() {
        focusedButton = .primary
    }
}
