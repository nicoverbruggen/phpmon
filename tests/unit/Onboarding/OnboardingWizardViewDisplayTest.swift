//
//  OnboardingWizardViewDisplayTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@MainActor
struct OnboardingWizardViewDisplayTest {
    // Once developer tools are detected after a manual install, the UI should move straight into
    // the Homebrew step instead of requiring an extra click to dismiss a completed-step screen.
    @Test func completed_developer_tools_state_does_not_block_homebrew_step() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        let view = OnboardingWizardView(
            viewModel: viewModel,
            hasDismissedIntroduction: true
        )

        #expect(view.activeStepNumber == 2)
        #expect(view.primaryButtonTitle == "onboarding_wizard.buttons.copy_command".localized)
    }

    // The standard onboarding flow should still begin on the introduction screen.
    @Test func full_setup_flow_starts_on_introduction() {
        let view = OnboardingWizardView(
            viewModel: OnboardingWizardViewModel(hasLoaded: true)
        )

        #expect(view.isShowingIntroduction)
    }

    // The Valet-only flow should skip the introduction and open directly on the Valet step.
    @Test func valet_only_flow_skips_introduction_in_the_view() {
        let viewModel = OnboardingWizardViewModel(
            flow: ValetInstallOnboardingFlow(),
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: true,
                composerInstalled: true
            ),
            hasLoaded: true
        )
        let view = OnboardingWizardView(
            viewModel: viewModel,
            entryMode: .firstRequiredStep
        )

        #expect(!view.isShowingIntroduction)
        #expect(view.activeStepNumber == 4)
        #expect(view.primaryButtonTitle == "onboarding_wizard.buttons.install_valet".localized)
    }
}
