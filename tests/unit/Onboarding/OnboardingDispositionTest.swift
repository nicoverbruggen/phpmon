//
//  OnboardingDispositionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct OnboardingDispositionTest {
    // A system without Homebrew is treated as a clear first-run onboarding case.
    @Test func missing_homebrew_shows_wizard() async {
        let container = prepareContainer(
            withFiles: [:],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // Homebrew on its own still counts as a fresh setup when no other prerequisites exist yet.
    @Test func fresh_homebrew_only_setup_shows_wizard() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // If PHP is already present but the first launch has not completed yet, onboarding should still open.
    @Test func php_presence_still_shows_wizard_on_first_launch_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ],
            hasPhpBinary: true
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // Composer alone does not suppress onboarding on the first launch when core setup is incomplete.
    @Test func composer_presence_still_shows_wizard_on_first_launch_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // Auxiliary tooling like Valet still counts as an incomplete first-launch setup.
    @Test func valet_presence_still_shows_wizard_on_first_launch_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "~/.config/valet": .fake(.directory)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // Existing Homebrew services alone should still open the wizard until PHP and Composer are installed.
    @Test func nginx_presence_still_shows_wizard_on_first_launch_partial_setup() async {
        let container = prepareContainer(
            withFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/opt/nginx": .fake(.directory)
            ],
            hasPhpBinary: false
        )

        #expect(await Startup.onboardingDisposition(in: container) == .wizard)
    }

    // PATH validation should only pass when Homebrew and Composer appear as exact PATH entries.
    @Test func path_configuration_requires_exact_path_entries() async {
        let container = prepareContainer(
            withFiles: [:],
            hasPhpBinary: false
        )
        (container.shell as? TestableShell)?.PATH = [
            "/usr/local/bin",
            "/opt/homebrew/bin-old",
            "/Users/fake/.composer/vendor/bin-backup"
        ].joined(separator: ":")

        #expect(!ShellEnvironment(container).hasRequiredOnboardingPaths())
    }

    // PATH validation should allow Homebrew and Composer entries even when the phpmon helper bin is absent.
    @Test func path_configuration_accepts_required_entries_without_phpmon_helper_bin() async {
        let container = prepareContainer(
            withFiles: [:],
            hasPhpBinary: false
        )
        (container.shell as? TestableShell)?.PATH = [
            "$HOME/.composer/vendor/bin/",
            "/opt/homebrew/bin/"
        ].joined(separator: ":")

        #expect(ShellEnvironment(container).hasRequiredOnboardingPaths())
    }

    private func prepareContainer(
        withFiles files: [String: FakeFile],
        hasPhpBinary: Bool
    ) -> Container {
        let container = Container()
        container.withFakeSystemContext(architecture: "arm64")
        container.bind(coreOnly: true, commandTracking: false)

        container.overrideFake(
            shellExpectations: [
                "/usr/bin/xcode-select -p": .instant("/Library/Developer/CommandLineTools"),
                "ls \(container.paths.optPath) | grep php": .instant(hasPhpBinary ? "php\n" : "")
            ],
            fileSystemFiles: files,
            commandTracking: false
        )

        return container
    }
}
