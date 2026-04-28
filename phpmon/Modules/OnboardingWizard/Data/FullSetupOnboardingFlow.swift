//
//  FullSetupOnboardingFlow.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct FullSetupOnboardingFlow: OnboardingFlowDefinition {
    let entryStep: OnboardingWizardViewModel.Step = .introduction
    let displayBaseline = OnboardingWizardViewModel.StepProgress()
}
