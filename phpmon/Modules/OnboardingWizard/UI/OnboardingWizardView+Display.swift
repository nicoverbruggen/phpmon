//
//  OnboardingWizardView+Display.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension OnboardingWizardView {
    var isShowingIntroduction: Bool {
        return viewState.isShowingIntroduction
    }

    var primaryButtonTitle: String {
        return viewState.primaryButtonTitle
    }

    var primaryButtonDisabled: Bool {
        return viewState.primaryButtonDisabled
    }

    var activeStepNumber: Int? {
        return viewState.activeStepNumber
    }
}

extension StepStatus {
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
