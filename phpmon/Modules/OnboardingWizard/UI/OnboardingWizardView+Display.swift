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
        if isShowingIntroduction {
            return "onboarding_wizard.buttons.start_setup".localized
        }

        if isDisplayingCompletedStep {
            return "onboarding_wizard.buttons.continue".localized
        }

        return viewModel.primaryButtonTitle
    }

    var primaryButtonDisabled: Bool {
        if isShowingIntroduction {
            return !viewModel.hasLoaded
        }

        if isDisplayingCompletedStep {
            return !viewModel.hasLoaded || viewModel.state == .running
        }

        return viewModel.primaryButtonDisabled
    }

    var activeStepNumber: Int? {
        if isShowingIntroduction {
            return nil
        }

        if isDisplayingCompletedStep, let displayedStepNumber {
            return displayedStepNumber
        }

        return actionableStepNumber
    }

    var actionableStepNumber: Int {
        switch viewModel.action {
        case .installDeveloperTools, .recheckDeveloperTools:
            return 1
        case .installHomebrew, .recheckHomebrew, .fixPathAutomatically, .recheckPath:
            return 2
        case .installPhpComposer:
            return 3
        case .installValet:
            return 4
        case .continueToStartup:
            return 5
        }
    }

    var isDisplayingCompletedStep: Bool {
        guard let displayedStepNumber else {
            return false
        }

        return isStepCompleted(displayedStepNumber)
            && displayedStepNumber == 1
            && viewModel.action == .recheckDeveloperTools
            && displayedStepNumber < actionableStepNumber
            && viewModel.state != .running
    }

    var displayedDetailTitle: String {
        guard isDisplayingCompletedStep else {
            return viewModel.detailTitle
        }

        return "onboarding_wizard.detail.developer_tools.title".localized
    }

    var displayedDetailDescription: String {
        guard isDisplayingCompletedStep else {
            return viewModel.detailDescription
        }

        return "onboarding_wizard.detail.developer_tools.completed".localized
    }

    var currentProgressText: String {
        if isShowingIntroduction {
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

    func stepStatus(for number: Int) -> StepStatus {
        if activeStepNumber == number {
            switch viewModel.state {
            case .running:
                return .running
            case .failed:
                return .failed
            case .idle, .waitingForManualCompletion:
                return .active
            }
        }

        return isStepCompleted(number) ? .completed : .pending
    }

    func isStepCompleted(_ number: Int) -> Bool {
        let progress = viewModel.displayProgress

        switch number {
        case 1:
            return progress.developerToolsInstalled
        case 2:
            return progress.developerToolsInstalled
                && progress.homebrewInstalled
                && progress.pathConfigured
        case 3:
            return progress.phpInstalled
                && progress.composerInstalled
        case 4:
            return viewModel.skippedValetSetup
                || (progress.valetInstalled
                    && progress.valetTrusted)
        default:
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
