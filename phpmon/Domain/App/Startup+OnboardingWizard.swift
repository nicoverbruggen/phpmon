//
//  Startup+OnboardingWizard.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Startup {
    enum OnboardingDisposition: Equatable {
        /** Displays the full setup wizard for users on a new machine or lacking all key dependencies.
         This is an additional extra step before all normal health checks at startup. */
        case wizard

        /** Skips the full setup wizard, and immediately does all normal health checks at startup. */
        case normal
    }

    enum OnboardingWizardOutcome: Equatable {
        case completed
        case completedInStandaloneMode
        case skipped
    }

    /**
     Determines whether the onboarding wizard should be shown for a genuinely fresh setup.

     The wizard is only intended for "new machine" scenarios:
     - Homebrew is missing entirely, or
     - Homebrew exists and none of the onboarding prerequisites are present yet.

     Any partial setup should fall through to the regular startup checks immediately.
     */
    func onboardingDisposition() async -> OnboardingDisposition {
        return await Self.onboardingDisposition(in: container)
    }

    @MainActor
    func showOnboardingWizard(
        exitsApplicationOnClose: Bool = true,
        flow: any OnboardingFlowDefinition = FullSetupOnboardingFlow()
    ) async -> OnboardingWizardOutcome {
        return await OnboardingWizardWindowController
            .create(
                exitsApplicationOnClose: exitsApplicationOnClose,
                flow: flow
            )
            .showModal()
    }

    static func onboardingDisposition(
        in container: Container
    ) async -> OnboardingDisposition {
        return await Toolchain(container).onboardingDisposition()
    }
}
