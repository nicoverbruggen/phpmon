//
//  OnboardingWizardView+Display.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension OnboardingWizardView {
    var primaryButtonTitle: String {
        return viewModel.primaryButtonTitle
    }

    var primaryButtonDisabled: Bool {
        return viewModel.primaryButtonDisabled
    }

    var activeStepNumber: Int? {
        switch viewModel.currentStep {
        case .introduction:
            return nil
        case .developerTools:
            return 1
        case .homebrew:
            return 2
        case .phpComposer:
            return 3
        case .valet:
            return 4
        case .ready:
            return 5
        }
    }

    var displayedDetailTitle: String {
        return viewModel.detailTitle
    }

    var displayedDetailDescription: String {
        return viewModel.detailDescription
    }

    var currentProgressText: String {
        if viewModel.currentStep == .introduction {
            return "onboarding_wizard.progress.introduction".localized
        }

        guard let activeStepNumber else {
            return "onboarding_wizard.progress.step".localized(totalWizardSteps)
        }

        return "onboarding_wizard.progress.step".localized(activeStepNumber)
    }

    var timelineLineColor: Color {
        Color.secondary.opacity(0.16)
    }

    func stepStatus(for step: OnboardingWizardViewModel.Step) -> StepStatus {
        if viewModel.currentStep == step {
            switch viewModel.state {
            case .running:
                return .running
            case .failed:
                return .failed
            case .idle, .waitingForManualCompletion:
                return .active
            }
        }

        return isStepCompleted(step) ? .completed : .pending
    }

    func isStepCompleted(_ step: OnboardingWizardViewModel.Step) -> Bool {
        let progress = viewModel.displayProgress

        switch step {
        case .introduction:
            return viewModel.hasCompletedIntroduction
        case .developerTools:
            return progress.developerToolsInstalled
        case .homebrew:
            return progress.developerToolsInstalled
                && progress.homebrewInstalled
                && progress.pathConfigured
        case .phpComposer:
            return progress.phpInstalled
                && progress.composerInstalled
        case .valet:
            return viewModel.skippedValetSetup
                || (progress.valetInstalled
                    && progress.valetTrusted)
        case .ready:
            return false
        }
    }
}

enum StepStatus {
    case pending
    case active
    case running
    case failed
    case completed

    var isActive: Bool {
        switch self {
        case .active, .running, .failed:
            return true
        case .pending, .completed:
            return false
        }
    }

    var timelineDotColor: Color {
        switch self {
        case .active, .running:
            return Color.accentColor
        case .failed:
            return Color.red.opacity(0.85)
        case .completed:
            return Color.secondary.opacity(0.45)
        case .pending:
            return Color.secondary.opacity(0.24)
        }
    }
}
