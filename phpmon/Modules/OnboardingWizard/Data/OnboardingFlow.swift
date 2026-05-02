//
//  OnboardingFlowDefinition.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

enum OnboardingStep: Hashable {
    case introduction
    case developerTools
    case homebrew
    case phpComposer
    case valet
    case ready
}

enum OnboardingRunState: Equatable {
    case idle
    case running
    case waitingForManualCompletion
    case failed
}

enum OnboardingAction: Equatable {
    case startSetup
    case installDeveloperTools
    case recheckDeveloperTools
    case installHomebrew
    case recheckHomebrew
    case fixPathAutomatically
    case recheckPath
    case installPhpComposer
    case installValet
    case continueToStartup
}

struct OnboardingProgress: Equatable {
    var developerToolsInstalled: Bool = false
    var homebrewInstalled: Bool = false
    var pathConfigured: Bool = false
    var phpInstalled: Bool = false
    var composerInstalled: Bool = false
    var valetInstalled: Bool = false
    var valetTrusted: Bool = false

    var coreToolingInstalled: Bool {
        developerToolsInstalled
            && homebrewInstalled
            && pathConfigured
            && phpInstalled
            && composerInstalled
    }

    var valetSetupInstalled: Bool {
        valetInstalled && valetTrusted
    }

    func overlayingForDisplay(with baseline: OnboardingProgress) -> OnboardingProgress {
        return OnboardingProgress(
            developerToolsInstalled: developerToolsInstalled || baseline.developerToolsInstalled,
            homebrewInstalled: homebrewInstalled || baseline.homebrewInstalled,
            pathConfigured: pathConfigured || baseline.pathConfigured,
            phpInstalled: phpInstalled || baseline.phpInstalled,
            composerInstalled: composerInstalled || baseline.composerInstalled,
            valetInstalled: valetInstalled || baseline.valetInstalled,
            valetTrusted: valetTrusted || baseline.valetTrusted
        )
    }
}

enum OnboardingAlertState: Equatable {
    case skipConfirmation
    case skipValetConfirmation
    case developerToolsIncomplete
    case valetSudoersCleanupFailed(command: String)
}

protocol OnboardingFlowDefinition {
    var entryStep: OnboardingStep { get }
    var displayBaseline: OnboardingProgress { get }
}

struct FullSetupOnboardingFlow: OnboardingFlowDefinition {
    let entryStep: OnboardingStep = .introduction
    let displayBaseline = OnboardingProgress()
}

struct ValetInstallOnboardingFlow: OnboardingFlowDefinition {
    let entryStep: OnboardingStep = .valet
    let displayBaseline = OnboardingProgress(
        developerToolsInstalled: true,
        homebrewInstalled: true,
        pathConfigured: true,
        phpInstalled: true,
        composerInstalled: true
    )
}
