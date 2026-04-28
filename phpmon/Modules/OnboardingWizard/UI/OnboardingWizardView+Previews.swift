//
//  OnboardingWizardView+Previews.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

#Preview("Introduction") {
    OnboardingWizardView.preview(progress: .init())
}

#Preview("Step 1: Command Line Tools") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init()
    )
}

#Preview("Step 2: Homebrew") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(developerToolsInstalled: true)
    )
}

#Preview("Step 2: PATH") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true
        )
    )
}

#Preview("Step 3: PHP & Composer") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true,
            pathConfigured: true
        )
    )
}

#Preview("Step 4: Valet") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true,
            pathConfigured: true,
            phpInstalled: true,
            composerInstalled: true
        )
    )
}

#Preview("Step 5: Ready") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true,
            pathConfigured: true,
            phpInstalled: true,
            composerInstalled: true,
            valetInstalled: true,
            valetTrusted: true
        )
    )
}

#Preview("Running") {
    OnboardingWizardView.preview(
        hasCompletedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true
        ),
        state: .running,
        outputLines: [
            OutputLine(text: "Updating your ~/.zshrc PATH entries...\n", stream: .stdOut)
        ]
    )
}

private extension OnboardingWizardView {
    static func preview(
        flow: any OnboardingFlowDefinition = FullSetupOnboardingFlow(),
        hasCompletedIntroduction: Bool? = nil,
        progress: OnboardingWizardViewModel.StepProgress,
        state: OnboardingWizardViewModel.State = .idle,
        outputLines: [OutputLine] = []
    ) -> OnboardingWizardView {
        return OnboardingWizardView(
            viewModel: OnboardingWizardViewModel(
                flow: flow,
                progress: progress,
                state: state,
                outputLines: outputLines,
                hasCompletedIntroduction: hasCompletedIntroduction,
                hasLoaded: true
            ),
            isShowingSkipConfirmation: false,
            isShowingSkipValetConfirmation: false
        )
    }
}
