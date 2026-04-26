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

    // The onboarding PATH guidance should include PHP Monitor helpers before the other required bins.
    @Test func onboarding_path_instructions_include_php_monitor_helpers() {
        let lines = ShellEnvironment(prepareContainer(architecture: "arm64")).pathInstructionLines()

        #expect(
            lines == [
                "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH",
                "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH",
                "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
            ]
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
        #expect(viewModel.commandTitle == "onboarding_wizard.command.homebrew.title".localized)
        #expect(viewModel.commandLines == [Toolchain.Commands.homebrewInstall])
        #expect(!viewModel.showsTerminalOutput)
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

    // Installing the required packages should mark the third step complete once both binaries exist.
    // The shared shell PATH refresh behavior is covered separately, so this test only verifies
    // the PHP and Composer portion of the transition.
    @Test func installing_php_and_composer_refreshes_progress() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            pathConfigured: true,
            shell: [
                "/opt/homebrew/bin/brew tap shivammathur/php": .instant("Tapped shivammathur/php.\n"),
                "/opt/homebrew/bin/brew tap shivammathur/extensions": .instant("Tapped shivammathur/extensions.\n"),
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
        #expect(viewModel.action == .installValet)
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

    // Installing Valet should run the Composer package install, trust command and Valet setup,
    // then mark the fourth step complete.
    @Test func installing_valet_refreshes_progress() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            pathConfigured: true,
            shell: [
                "/opt/homebrew/bin/composer global require laravel/valet": BatchFakeShellOutput(
                    items: [.instant("Installed Valet.\n")],
                    transactions: [
                        .write("", to: "/opt/homebrew/bin/valet")
                    ]
                ),
                "/opt/homebrew/bin/valet trust": BatchFakeShellOutput(
                    items: [.instant("Configured Valet sudoers.\n")],
                    transactions: [
                        .shell(
                            "cat /private/etc/sudoers.d/brew",
                            .instant("""
                            Cmnd_Alias BREW = /opt/homebrew/bin/brew *
                            %admin ALL=(root) NOPASSWD:SETENV: BREW
                            """)
                        ),
                        .shell(
                            "cat /private/etc/sudoers.d/valet",
                            .instant("""
                            Cmnd_Alias VALET = /opt/homebrew/bin/valet *
                            %admin ALL=(root) NOPASSWD:SETENV: VALET
                            """)
                        )
                    ]
                ),
                "/opt/homebrew/bin/valet install": BatchFakeShellOutput(
                    items: [.instant("Configured Valet.\n")],
                    transactions: [
                        .mkdir("~/.config/valet"),
                        .write(
                            """
                            {
                              "tld": "test",
                              "paths": [
                                "/Users/fake/.config/valet/Sites",
                                "/Users/fake/Sites"
                              ],
                              "loopback": "127.0.0.1"
                            }
                            """,
                            to: "~/.config/valet/config.json"
                        )
                    ]
                ),
                "cat /private/etc/sudoers.d/brew": .instant(""),
                "cat /private/etc/sudoers.d/valet": .instant("")
            ],
            files: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary),
                "/opt/homebrew/bin/php": .fake(.binary)
            ]
        )

        let viewModel = OnboardingWizardViewModel(
            container: container,
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

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.completedSteps.contains(4))
        #expect(viewModel.action == .continueToStartup)
    }

    // The Homebrew step should copy the manual install command and wait for the user to
    // complete the installer in Terminal before the wizard checks again.
    @Test func requesting_homebrew_install_copies_command_and_waits_for_recheck() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            shell: [
                Toolchain.Commands.homebrewInstall: BatchFakeShellOutput(
                    items: [.instant("Installed Homebrew.\n")],
                    transactions: [
                        .write("", to: "/opt/homebrew/bin/brew")
                    ]
                ),
                "ls /opt/homebrew/opt | grep php": .instant("")
            ],
            files: [:]
        )

        let viewModel = OnboardingWizardViewModel(
            container: container,
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.action == .recheckHomebrew)
        #expect(!viewModel.progress.homebrewInstalled)
        #expect(viewModel.showsStatusBanner)
        #expect(!viewModel.showsTerminalOutput)
        #expect(viewModel.statusBannerText == "onboarding_wizard.output.homebrew_command_copied".localized)
        #expect(viewModel.outputLines.contains(where: { $0.text.contains("Installed Homebrew.") }))
        #expect(viewModel.outputLines.contains(where: {
            $0.text.contains("onboarding_wizard.output.homebrew_command_copied".localized)
        }))
    }

    // After the user has run the copied Homebrew command, checking again should refresh the
    // toolchain state and advance the wizard into the PATH step.
    @Test func rechecking_homebrew_refreshes_progress_after_manual_install() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            shell: [
                Toolchain.Commands.homebrewInstall: BatchFakeShellOutput(
                    items: [.instant("Installing Homebrew...\n")],
                    transactions: [
                        .write("", to: "/opt/homebrew/bin/brew")
                    ]
                ),
                "ls /opt/homebrew/opt | grep php": .instant("")
            ],
            files: [:]
        )

        let viewModel = OnboardingWizardViewModel(
            container: container,
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        var task = viewModel.performPrimaryAction()
        await task?.value

        task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.progress.homebrewInstalled)
        #expect(viewModel.action == .fixPathAutomatically)
        #expect(viewModel.outputLines.isEmpty)
    }

    // Manual PATH rechecks should use a plain status message instead of the terminal output panel.
    @Test func failed_manual_path_recheck_uses_status_banner() async {
        let container = prepareFakeContainer(
            architecture: "arm64",
            configuredShell: "/bin/bash",
            shell: [
                "ls /opt/homebrew/opt | grep php": .instant("")
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
                pathConfigured: false
            ),
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.action == .recheckPath)
        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.showsStatusBanner)
        #expect(!viewModel.showsTerminalOutput)
        #expect(viewModel.statusBannerText == "onboarding_wizard.output.step_not_resolved".localized)
    }

    // Once developer tools are detected after a manual install, the UI should move straight into
    // the Homebrew step instead of requiring an extra click to dismiss a completed-step screen.
    @Test func completed_developer_tools_state_does_not_block_homebrew_step() {
        let viewModel = OnboardingWizardViewModel(
            progress: .init(
                developerToolsInstalled: true,
                homebrewInstalled: false,
                pathConfigured: false
            ),
            hasLoaded: true
        )

        let view = OnboardingWizardView(
            viewModel: viewModel,
            hasStartedWizard: true,
            displayedStepNumber: 1
        )

        #expect(!view.isDisplayingCompletedStep)
        #expect(view.activeStepNumber == 2)
        #expect(view.primaryButtonTitle == "onboarding_wizard.buttons.copy_command".localized)
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
        configuredShell: String = "/bin/zsh",
        pathConfigured: Bool = false,
        shell: [String: BatchFakeShellOutput],
        files: [String: FakeFile],
        includeDeveloperTools: Bool = true
    ) -> Container {
        let container = Container()
        container.withFakeSystemContext(
            architecture: architecture,
            configuredShell: configuredShell
        )
        container.bind(coreOnly: true, commandTracking: false)
        let valetShell: [String: BatchFakeShellOutput] = [
            "cat /private/etc/sudoers.d/brew": .instant(""),
            "cat /private/etc/sudoers.d/valet": .instant("")
        ]
        let developerToolsShell: [String: BatchFakeShellOutput] = includeDeveloperTools
            ? ["/usr/bin/xcode-select -p": .instant("/Library/Developer/CommandLineTools")]
            : [:]

        container.overrideFake(
            shellExpectations: valetShell
                .merging(developerToolsShell) { (_, new) in new }
                .merging(shell) { (_, new) in new },
            fileSystemFiles: files,
            commandTracking: false
        )

        if pathConfigured, let shell = container.shell as? TestableShell {
            shell.PATH = [
                "/usr/local/bin",
                "/usr/bin",
                "/bin",
                "/usr/sbin",
                "\(container.paths.homePath)/.config/phpmon/bin",
                "\(container.paths.homePath)/.composer/vendor/bin",
                container.paths.binPath
            ].joined(separator: ":")
        }

        return container
    }
}
