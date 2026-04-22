//
//  StartupOnboardingWizardTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct StartupOnboardingWizardTest {
    // A system without Homebrew is treated as a clear first-run onboarding case.
    @Test func missing_homebrew_shows_wizard() async {
        let container = prepareContainer(
            withFiles: [:],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingWizardStartupDisposition(in: container) == .wizard)
        #expect(await Startup.shouldShowOnboardingWizard(in: container))
    }

    // Homebrew on its own still counts as a fresh setup when no other prerequisites exist yet.
    @Test func fresh_homebrew_only_setup_shows_wizard() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingWizardStartupDisposition(in: container) == .wizard)
    }

    // If PHP is already present, startup should treat the machine as partially configured.
    @Test func php_presence_skips_wizard_for_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ],
            hasPhpBinary: true
        )

        #expect(await Startup.onboardingWizardStartupDisposition(in: container) == .normal)
        #expect(!(await Startup.shouldShowOnboardingWizard(in: container)))
    }

    // Composer alone is enough to classify the environment as partial instead of brand new.
    @Test func composer_presence_skips_wizard_for_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingWizardStartupDisposition(in: container) == .normal)
    }

    // Existing Valet state should bypass onboarding and defer to the regular startup checks.
    @Test func valet_presence_skips_wizard_for_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "~/.config/valet": .fake(.directory)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingWizardStartupDisposition(in: container) == .normal)
    }

    private func prepareContainer(
        withFiles files: [String: FakeFile],
        hasPhpBinary: Bool
    ) -> Container {
        let container = Container()
        container.systemContext.architectureOverride = "arm64"
        container.bind(coreOnly: true, commandTracking: false)

        container.overrideFake(
            shellExpectations: [
                "ls \(container.paths.optPath) | grep php": .instant(hasPhpBinary ? "php\n" : "")
            ],
            fileSystemFiles: files,
            commandTracking: false
        )

        return container
    }
}
