//
//  OnboardingTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

final class OnboardingTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Core onboarding flow

    // If Command Line Tools are missing, the wizard should request their installation first and only
    // continue through the rest of setup once the mocked system command reports them as installed.
    final func test_launch_runs_onboarding_wizard_flow_that_installs_developer_tools() throws {
        let flow = onboardingFlow(with: .developerToolsMissing)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installDeveloperTools()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.installValet()
        flow.continueToMenu()
        flow.terminate()
    }

    // If Command Line Tools already exist, the wizard should acknowledge step 1 and continue through
    // the mocked Homebrew, PATH, and PHP/Composer setup before regular startup enables the menu.
    final func test_launch_runs_onboarding_wizard_flow_when_developer_tools_are_already_installed() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.assertIntroStepsComplete(count: 1)
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.installValet()
        flow.continueToMenu()
        flow.terminate()
    }

    // If core setup is already partially present on a first launch, the wizard should still open,
    // show the introduction, mark the completed steps, and continue at PHP/Composer.
    final func test_launch_runs_wizard_for_first_launch_partial_setup_when_php_and_composer_are_missing() throws {
        let flow = onboardingFlow(with: .firstLaunchPartialSetup)

        flow.assertDidOpenWizard()
        flow.assertIntroStepsComplete(count: 2)
        flow.startWizard()
        flow.installPhp()
        flow.installValet()
        flow.continueToMenu()
        flow.terminate()
    }

    // MARK: - PATH setup variants

    // If the user's shell is not zsh, the wizard should show the manual PATH instructions
    // after Homebrew is installed instead of offering the automatic PATH fixer.
    final func test_launch_shows_manual_path_instructions_for_non_zsh_shells() throws {
        let flow = onboardingFlow(with: .manualPathFixRequired)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.assertManualPathInstructions()
        flow.terminate()
    }

    // MARK: - Valet flow variants

    // Users can skip the optional Valet step, confirm Standalone Mode, and still finish
    // onboarding successfully without being forced through Valet installation.
    final func test_launch_can_skip_valet_and_continue_in_standalone_mode() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.skipValet()
        flow.continueToMenu()
        flow.terminate()
    }

    // Setup cannot be skipped while a command is actively running, so partially completed
    // installs are not abandoned in an unknown state.
    final func test_launch_disables_skip_setup_while_install_step_is_running() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.beginPhpInstall()
        flow.assertSkipSetupIsDisabled()
        flow.assertValetInstallIsAvailable(timeout: 5.0)
        flow.terminate()
    }

    // Valet onboarding now pauses twice for privileged actions in UI tests:
    // once to install temporary permissions and once to remove them afterwards.
    final func test_launch_requires_approving_privileged_valet_actions() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.installValet()
        flow.continueToMenu()
        flow.terminate()
    }

    // Denying the temporary admin request should fail the Valet step without advancing past it.
    final func test_launch_can_deny_privileged_valet_install_and_retry() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.beginValetInstall()
        flow.denyPrivilegedCommand()

        flow.assertValetInstallIsAvailable()
        flow.assertContinueButtonIsUnavailable()
        flow.terminate()
    }

    // If cleanup is denied after Valet succeeds, the wizard should keep the install complete
    // and show the cleanup warning before allowing the user to continue.
    final func test_launch_surfaces_cleanup_warning_when_privileged_cleanup_is_denied() throws {
        let flow = onboardingFlow(with: .developerToolsAlreadyInstalled)

        flow.assertDidOpenWizard()
        flow.startWizard()
        flow.installHomebrew()
        flow.configurePathAutomatically()
        flow.installPhp()
        flow.beginValetInstall()
        flow.approvePrivilegedCommand()
        flow.denyPrivilegedCommand()

        flow.assertCleanupWarningIsVisible()
        flow.dismissCleanupWarning()
        flow.assertContinueButtonIsAvailable()
        flow.terminate()
    }
}
