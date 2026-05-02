//
//  OnboardingFlowDefinition.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

protocol OnboardingFlowDefinition {
    var entryStep: OnboardingWizardViewModel.Step { get }
    var displayBaseline: OnboardingWizardViewModel.StepProgress { get }
}

struct FullSetupOnboardingFlow: OnboardingFlowDefinition {
    let entryStep: OnboardingWizardViewModel.Step = .introduction
    let displayBaseline = OnboardingWizardViewModel.StepProgress()
}

struct ValetInstallOnboardingFlow: OnboardingFlowDefinition {
    let entryStep: OnboardingWizardViewModel.Step = .valet
    let displayBaseline = OnboardingWizardViewModel.StepProgress(
        developerToolsInstalled: true,
        homebrewInstalled: true,
        pathConfigured: true,
        phpInstalled: true,
        composerInstalled: true
    )
}
