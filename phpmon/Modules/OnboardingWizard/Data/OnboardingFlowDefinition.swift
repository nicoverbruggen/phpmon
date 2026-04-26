//
//  OnboardingFlowDefinition.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

enum OnboardingEntryMode {
    case introduction
    case firstRequiredStep
}

protocol OnboardingFlowDefinition {
    var entryMode: OnboardingEntryMode { get }
    var displayBaseline: OnboardingWizardViewModel.StepProgress { get }
}
