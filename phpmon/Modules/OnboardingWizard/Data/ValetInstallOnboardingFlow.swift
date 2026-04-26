//
//  ValetInstallOnboardingFlow.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct ValetInstallOnboardingFlow: OnboardingFlowDefinition {
    let entryMode: OnboardingEntryMode = .firstRequiredStep
    let displayBaseline = OnboardingWizardViewModel.StepProgress(
        developerToolsInstalled: true,
        homebrewInstalled: true,
        pathConfigured: true,
        phpInstalled: true,
        composerInstalled: true
    )
}
