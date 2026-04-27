//
//  OnboardingWizardViewModelTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@MainActor
struct OnboardingWizardViewModelTest {
    // Missing developer tools should make the first button launch Apple's installer.
    @Test func missing_developer_tools_uses_installer_action() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: false,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installDeveloperTools)
        #expect(viewModel.completedSteps.isEmpty)
    }

    // The wizard should not allow actions until the initial environment refresh has completed.
    @Test func primary_action_is_disabled_until_initial_progress_loads() {
        let viewModel = OnboardingWizardViewModel(hasLoaded: false)

        #expect(viewModel.primaryButtonDisabled)
        #expect(viewModel.performPrimaryAction() == nil)
    }

    // Once developer tools are present, the wizard should advance to Homebrew setup.
    @Test func homebrew_install_is_next_after_developer_tools() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installHomebrew)
        #expect(viewModel.completedSteps == Set([1]))
        #expect(viewModel.commandTitle == "onboarding_wizard.command.homebrew.title".localized)
        #expect(viewModel.commandLines == [Toolchain.Commands.homebrewInstall])
        #expect(!viewModel.showsTerminalOutput)
    }

    // zsh users should get an automatic PATH fix once Homebrew is installed.
    @Test func zsh_users_get_automatic_path_fix_action() {
        let container = makeOnboardingContainer(architecture: "arm64", configuredShell: "/bin/zsh")
        let viewModel = OnboardingWizardViewModel(
            container: container,
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .fixPathAutomatically)
    }

    // Non-zsh users should be asked to update PATH manually and then re-check.
    @Test func non_zsh_users_are_prompted_to_recheck_path_manually() {
        let container = makeOnboardingContainer(architecture: "arm64", configuredShell: "/bin/bash")
        let viewModel = OnboardingWizardViewModel(
            container: container,
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .recheckPath)
    }

    // Once PATH is ready, the wizard should advance into the required PHP and Composer step.
    @Test func php_and_composer_install_is_next_after_path_setup() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: false,
                composerInstalled: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installPhpComposer)
        #expect(viewModel.completedSteps == Set([1, 2]))
    }

    // The PHP/Composer install step should present a single action button without showing
    // the underlying brew command to run manually.
    @Test func php_and_composer_step_does_not_show_command_block() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: false,
                composerInstalled: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installPhpComposer)
        #expect(viewModel.commandTitle == nil)
        #expect(viewModel.commandLines.isEmpty)
    }

    // Once the required packages are installed, the wizard can hand control back to startup.
    @Test func fully_prepared_core_setup_enables_continue() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: true,
                composerInstalled: true,
                valetInstalled: true,
                valetTrusted: true
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .continueToStartup)
        #expect(viewModel.completedSteps == Set([1, 2, 3, 4]))
    }

    // Once PHP and Composer are ready, the wizard should continue into the Valet setup step.
    @Test func valet_install_is_next_after_php_and_composer_setup() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: true,
                composerInstalled: true,
                valetInstalled: false,
                valetTrusted: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installValet)
        #expect(viewModel.completedSteps == Set([1, 2, 3]))
        #expect(viewModel.commandTitle == nil)
        #expect(viewModel.commandLines.isEmpty)
    }

    // The standalone-mode Valet flow should skip the earlier onboarding steps and land directly on Valet.
    @Test func valet_only_flow_jumps_straight_to_valet_install() {
        let viewModel = OnboardingWizardViewModel(
            flow: ValetInstallOnboardingFlow(),
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: true,
                composerInstalled: true,
                valetInstalled: false,
                valetTrusted: false
            ),
            hasLoaded: true
        )

        #expect(viewModel.action == .installValet)
        #expect(viewModel.progress.coreToolingInstalled)
        #expect(viewModel.completedSteps == Set([1, 2, 3]))
    }

    // The Valet-only flow should mark earlier steps complete in presentation without mutating
    // the underlying factual progress state.
    @Test func valet_only_flow_uses_display_progress_without_mutating_actual_progress() {
        let viewModel = OnboardingWizardViewModel(
            flow: ValetInstallOnboardingFlow(),
            progress: .init(),
            hasLoaded: true
        )

        #expect(!viewModel.progress.coreToolingInstalled)
        #expect(viewModel.displayProgress.coreToolingInstalled)
        #expect(viewModel.completedSteps == Set([1, 2, 3]))
    }

    // Skipping Valet should finish onboarding in Standalone Mode, while still marking the
    // optional Valet step as intentionally completed for the wizard UI.
    @Test func skipping_valet_completes_onboarding_in_standalone_mode() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: true,
                composerInstalled: true
            ),
            hasLoaded: true
        )
        var outcome: Startup.OnboardingWizardOutcome?
        viewModel.onComplete = {
            outcome = $0
        }

        viewModel.skipValetSetup()

        #expect(viewModel.action == .continueToStartup)
        #expect(viewModel.completedSteps == Set([1, 2, 3, 4]))

        _ = viewModel.performPrimaryAction()

        #expect(outcome == .completedInStandaloneMode)
    }
}
