//
//  OnboardingWizardViewModelTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import Testing

@MainActor
struct OnboardingWizardViewModelTest {
    // The Homebrew PATH line should use the Apple Silicon prefix on arm64 systems.
    @Test func homebrew_path_line_uses_detected_arm64_prefix() {
        let container = prepareContainer(architecture: "arm64")

        #expect(
            ShellEnvironment(container).homebrewBinPathExport
                == "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
        )
    }

    // The Homebrew PATH line should use the Intel prefix on x86_64 systems.
    @Test func homebrew_path_line_uses_detected_intel_prefix() {
        let container = prepareContainer(architecture: "x86_64")

        #expect(
            ShellEnvironment(container).homebrewBinPathExport
                == "export PATH=$HOME/bin:/usr/local/bin:$PATH"
        )
    }

    // Composer's global vendor bin path should always be inserted before Homebrew.
    @Test func composer_path_line_matches_documented_vendor_bin_location() {
        #expect(
            ShellEnvironment(prepareContainer(architecture: "arm64")).composerBinPathExport
                == "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH"
        )
    }

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
    }

    // zsh users should get an automatic PATH fix once Homebrew is installed.
    @Test func zsh_users_get_automatic_path_fix_action() {
        let container = prepareContainer(architecture: "arm64", configuredShell: "/bin/zsh")
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
        let container = prepareContainer(architecture: "arm64", configuredShell: "/bin/bash")
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

    // Once the required packages are installed, the wizard can hand control back to startup.
    @Test func fully_prepared_core_setup_enables_continue() {
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

        #expect(viewModel.action == .continueToStartup)
        #expect(viewModel.completedSteps == Set([1, 2, 3]))
    }

    // Installing the required packages should mark the third step complete once both binaries exist.
    // The shared shell PATH refresh behavior is covered separately, so this test only verifies
    // the PHP and Composer portion of the transition.
    @Test func installing_php_and_composer_refreshes_progress() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            shell: [
                "/opt/homebrew/bin/brew install php composer": BatchFakeShellOutput(
                    items: [.instant("Installing php and composer...\n")],
                    transactions: [
                        .write("", to: "/opt/homebrew/bin/php"),
                        .write("", to: "/opt/homebrew/bin/composer")
                    ]
                )
            ],
            files: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ]
        )

        let viewModel = OnboardingWizardViewModel(
            container: container,
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: true,
                pathConfigured: true,
                phpInstalled: false,
                composerInstalled: false
            ),
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.completedSteps.contains(3))
        #expect(viewModel.action != .installPhpComposer)
    }

    // Starting the Command Line Tools installer should pause for manual completion instead of
    // auto-advancing; pressing Continue should re-check and alert if the tools are still missing.
    @Test func developer_tools_install_requires_manual_continue_before_rechecking() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            shell: [
                "/usr/bin/xcode-select -p": .instant(
                    "xcode-select: error: unable to get active developer directory\n",
                    .stdErr
                ),
                "/usr/bin/xcode-select --install": .instant("Requested installer.\n"),
                "ls /opt/homebrew/opt | grep php": .instant("")
            ],
            files: [:],
            includeDeveloperTools: false
        )
        let viewModel = OnboardingWizardViewModel(container: container, hasLoaded: true)
        var didShowIncompleteAlert = false
        viewModel.onDeveloperToolsRecheckFailed = {
            didShowIncompleteAlert = true
        }

        var task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.action == .recheckDeveloperTools)
        #expect(viewModel.primaryButtonTitle == "onboarding_wizard.buttons.continue".localized)

        task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(didShowIncompleteAlert)
    }

    private func prepareContainer(
        architecture: String,
        configuredShell: String = "/bin/zsh"
    ) -> Container {
        let container = Container()
        container.withFakeSystemContext(
            architecture: architecture,
            configuredShell: configuredShell
        )
        container.bind(coreOnly: true, commandTracking: false)
        return container
    }

    private func prepareFakeContainer(
        architecture: String,
        shell: [String: BatchFakeShellOutput],
        files: [String: FakeFile],
        includeDeveloperTools: Bool = true
    ) -> Container {
        let container = Container()
        container.withFakeSystemContext(architecture: architecture)
        container.bind(coreOnly: true, commandTracking: false)
        let developerToolsShell: [String: BatchFakeShellOutput] = includeDeveloperTools
            ? ["/usr/bin/xcode-select -p": .instant("/Library/Developer/CommandLineTools")]
            : [:]

        container.overrideFake(
            shellExpectations: developerToolsShell.merging(shell) { (_, new) in new },
            fileSystemFiles: files,
            commandTracking: false
        )
        return container
    }
}
