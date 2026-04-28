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
        let app = launchOnboardingWizard(with: .developerToolsMissing)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        installDeveloperTools(app)
        completeRequiredInstallFlow(app)
    }

    // If Command Line Tools already exist, the wizard should acknowledge step 1 and continue through
    // the mocked Homebrew, PATH, and PHP/Composer setup before regular startup enables the menu.
    final func test_launch_runs_onboarding_wizard_flow_when_developer_tools_are_already_installed() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        assertIntroductionMarksCompletedSteps(app, count: 1)
        startWizard(app)
        completeRequiredInstallFlow(app)
    }

    // If core setup is already partially present on a first launch, the wizard should still open,
    // show the introduction, mark the completed steps, and continue at PHP/Composer.
    final func test_launch_runs_wizard_for_first_launch_partial_setup_when_php_and_composer_are_missing() throws {
        let app = launchOnboardingWizard(with: .firstLaunchPartialSetup)

        assertWizardOpenedInsteadOfStartupAlert(app)
        assertIntroductionMarksCompletedSteps(app, count: 2)
        startWizard(app)
        advanceToValetStep(app)
        completeValetAndFinish(app)
    }

    // MARK: - PATH setup variants

    // If the user's shell is not zsh, the wizard should show the manual PATH instructions
    // after Homebrew is installed instead of offering the automatic PATH fixer.
    final func test_launch_shows_manual_path_instructions_for_non_zsh_shells() throws {
        let app = launchOnboardingWizard(with: .manualPathFixRequired)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        installHomebrew(app)
        assertManualPathInstructions(app)

        app.terminate()
    }

    // MARK: - Valet flow variants

    // Users can skip the optional Valet step, confirm Standalone Mode, and still finish
    // onboarding successfully without being forced through Valet installation.
    final func test_launch_can_skip_valet_and_continue_in_standalone_mode() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        advanceToValetStep(app)
        skipValetAndContinueInStandaloneMode(app)

        app.terminate()
    }

    // Valet onboarding now pauses twice for privileged actions in UI tests:
    // once to install temporary permissions and once to remove them afterwards.
    final func test_launch_requires_approving_privileged_valet_actions() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        completeRequiredInstallFlow(app)
    }

    // Denying the temporary admin request should fail the Valet step without advancing past it.
    final func test_launch_can_deny_privileged_valet_install_and_retry() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        advanceToValetStep(app)
        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
        denyPrivilegedCommand(app)

        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)
        assertNotExists(app.buttons["onboarding_wizard.buttons.continue".localized], 1.0)

        app.terminate()
    }

    // If cleanup is denied after Valet succeeds, the wizard should keep the install complete
    // and show the cleanup warning before allowing the user to continue.
    final func test_launch_surfaces_cleanup_warning_when_privileged_cleanup_is_denied() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        advanceToValetStep(app)
        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
        approvePrivilegedCommand(app)
        denyPrivilegedCommand(app)

        assertExists(app.staticTexts["onboarding_wizard.alert.valet_sudoers_cleanup_failed.title".localized], 3.0)
        assertExists(app.buttons["generic.ok".localized], 3.0)
        click(app.buttons["generic.ok".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)

        app.terminate()
    }
}
