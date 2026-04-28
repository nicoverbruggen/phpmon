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
