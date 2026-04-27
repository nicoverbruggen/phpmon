//
//  OnboardingWizardShellEnvironmentTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct OnboardingWizardShellEnvironmentTest {
    // The Homebrew PATH line should use the Apple Silicon prefix on arm64 systems.
    @Test func homebrew_path_line_uses_detected_arm64_prefix() {
        let container = makeOnboardingContainer(architecture: "arm64")

        #expect(
            ShellEnvironment(container).homebrewBinPathExport
                == "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
        )
    }

    // The Homebrew PATH line should use the Intel prefix on x86_64 systems.
    @Test func homebrew_path_line_uses_detected_intel_prefix() {
        let container = makeOnboardingContainer(architecture: "x86_64")

        #expect(
            ShellEnvironment(container).homebrewBinPathExport
                == "export PATH=$HOME/bin:/usr/local/bin:$PATH"
        )
    }

    // Composer's global vendor bin path should always be inserted before Homebrew.
    @Test func composer_path_line_matches_documented_vendor_bin_location() {
        #expect(
            ShellEnvironment(makeOnboardingContainer(architecture: "arm64")).composerBinPathExport
                == "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH"
        )
    }

    // The onboarding PATH guidance should include PHP Monitor helpers before the other required bins.
    @Test func onboarding_path_instructions_include_php_monitor_helpers() {
        let lines = ShellEnvironment(makeOnboardingContainer(architecture: "arm64")).pathInstructionLines()

        #expect(
            lines == [
                "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH",
                "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH",
                "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
            ]
        )
    }
}
