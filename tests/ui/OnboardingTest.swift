//
//  OnboardingTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

final class OnboardingTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    final func test_launch_shows_onboarding_wizard_before_regular_startup_checks() throws {
        var configuration = TestableConfigurations.working
        configuration.filesystem["/opt/homebrew/bin/brew"] = nil

        let app = launch(
            waitForInitialization: false,
            with: configuration
        )

        assertAllExist([
            app.staticTexts["onboarding_wizard.title".localized],
            app.buttons["onboarding_wizard.buttons.continue".localized],
            app.buttons["onboarding_wizard.buttons.quit".localized]
        ], 3.0)

        click(app.buttons["onboarding_wizard.buttons.continue".localized])

        // TODO: once this wizard actually works, we will no longer see the notice that follows next, but that's for later

        assertAllExist([
            app.dialogs["generic.notice".localized],
            app.staticTexts["alert.homebrew_missing.title".localized],
            app.buttons["alert.homebrew_missing.quit".localized]
        ], 3.0)

        app.terminate()
    }
}
