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
        hasDismissedIntroduction: true,
        progress: .init()
    )
}

#Preview("Step 1: Already Complete") {
    OnboardingWizardView.preview(
        hasDismissedIntroduction: true,
        displayedStepNumber: 1,
        progress: .init(developerToolsInstalled: true)
    )
}

#Preview("Step 2: Homebrew") {
    OnboardingWizardView.preview(
        hasDismissedIntroduction: true,
        progress: .init(developerToolsInstalled: true)
    )
}

#Preview("Step 2: PATH") {
    OnboardingWizardView.preview(
        hasDismissedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true
        )
    )
}

#Preview("Step 3: PHP & Composer") {
    OnboardingWizardView.preview(
        hasDismissedIntroduction: true,
        progress: .init(
            developerToolsInstalled: true,
            homebrewInstalled: true,
            pathConfigured: true
        )
    )
}

#Preview("Step 4: Valet") {
    OnboardingWizardView.preview(
        hasDismissedIntroduction: true,
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
        hasDismissedIntroduction: true,
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
        hasDismissedIntroduction: true,
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
        entryMode: OnboardingEntryMode = .introduction,
        hasDismissedIntroduction: Bool = false,
        displayedStepNumber: Int? = nil,
        progress: OnboardingWizardViewModel.StepProgress,
        state: OnboardingWizardViewModel.State = .idle,
        outputLines: [OutputLine] = []
    ) -> OnboardingWizardView {
        return OnboardingWizardView(
            viewModel: OnboardingWizardViewModel(
                progress: progress,
                state: state,
                outputLines: outputLines,
                hasLoaded: true
            ),
            entryMode: entryMode,
            hasDismissedIntroduction: hasDismissedIntroduction,
            displayedStepNumber: displayedStepNumber
        )
    }
}
