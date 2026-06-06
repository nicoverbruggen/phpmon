//
//  OnboardingWizardViewModelStepsTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@MainActor
// swiftlint:disable type_body_length file_length
struct OnboardingWizardViewModelStepsTest {
    // Installing the required packages should mark the third step complete once both binaries exist.
    // The shared shell PATH refresh behavior is covered separately, so this test only verifies
    // the PHP and Composer portion of the transition.
    @Test func installing_php_and_composer_refreshes_progress() async {
        let container = makeOnboardingFakeContainer(
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.completedSteps.contains(.phpComposer))
        #expect(viewModel.action == .installValet)
    }

    // Installing Valet should run the Composer package install, trust command and Valet setup,
    // then mark the fourth step complete.
    @Test func installing_valet_refreshes_progress() async {
        let privilegedCommandRunner = OnboardingTestPrivilegedCommandRunner()
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            pathConfigured: true,
            shell: [
                "/opt/homebrew/bin/composer global require laravel/valet": BatchFakeShellOutput(
                    items: [.instant("Installed Valet.\n")],
                    transactions: [
                        .write("", to: "/Users/fake/.composer/vendor/bin/valet")
                    ]
                ),
                "/opt/homebrew/bin/brew install dnsmasq nginx": .instant("Installed dnsmasq and nginx.\n"),
                "/Users/fake/.composer/vendor/bin/valet install": BatchFakeShellOutput(
                    items: [.instant("Configured Valet.\n")],
                    transactions: [
                        .mkdir("~/.config/valet"),
                        .write("", to: "/opt/homebrew/bin/valet"),
                        .write(
                            """
                            {
                              "paths": [
                                "/Users/fake/.config/valet/Sites"
                              ],
                              "tld": "test",
                              "loopback": "127.0.0.1"
                            }
                            """,
                            to: "~/.config/valet/config.json"
                        )
                    ]
                ),
                "/Users/fake/.composer/vendor/bin/valet trust": BatchFakeShellOutput(
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
                "cat /private/etc/sudoers.d/brew": .instant(""),
                "cat /private/etc/sudoers.d/valet": .instant("")
            ],
            files: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary),
                "/opt/homebrew/bin/php": .fake(.binary)
            ],
            privilegedCommandRunner: privilegedCommandRunner
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.completedSteps.contains(.valet))
        #expect(viewModel.action == .continueToStartup)
        #expect(privilegedCommandRunner.requests.count == 2)
        #expect(privilegedCommandRunner.requests[0].1 == .onboardingValetTemporarySudoersInstall)
        #expect(privilegedCommandRunner.requests[1].1 == .onboardingValetTemporarySudoersCleanup)
    }

    // If the user denies the temporary admin request, Valet setup should fail in a retryable way
    // and keep the primary action on the same step.
    @Test func denying_valet_admin_access_fails_the_step_but_keeps_it_retryable() async {
        let privilegedCommandRunner = OnboardingTestPrivilegedCommandRunner(
            responses: [.deny]
        )
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            pathConfigured: true,
            shell: [:],
            files: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary),
                "/opt/homebrew/bin/php": .fake(.binary)
            ],
            privilegedCommandRunner: privilegedCommandRunner
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .failed)
        #expect(viewModel.action == .installValet)
        #expect(viewModel.outputLines.contains(where: {
            $0.text.contains("onboarding_wizard.output.valet_admin_access_denied".localized)
        }))
        #expect(privilegedCommandRunner.requests.count == 1)
        #expect(privilegedCommandRunner.requests[0].1 == .onboardingValetTemporarySudoersInstall)
    }

    // If cleanup is denied after Valet finishes installing, the wizard should stay complete and
    // surface the cleanup warning instead of rolling the step back.
    @Test func denying_valet_cleanup_keeps_the_step_complete_and_surfaces_warning() async {
        let privilegedCommandRunner = OnboardingTestPrivilegedCommandRunner(
            responses: [.approve(""), .deny]
        )
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            pathConfigured: true,
            shell: [
                "/opt/homebrew/bin/composer global require laravel/valet": BatchFakeShellOutput(
                    items: [.instant("Installed Valet.\n")],
                    transactions: [
                        .write("", to: "/Users/fake/.composer/vendor/bin/valet")
                    ]
                ),
                "/opt/homebrew/bin/brew install dnsmasq nginx": .instant("Installed dnsmasq and nginx.\n"),
                "/Users/fake/.composer/vendor/bin/valet install": BatchFakeShellOutput(
                    items: [.instant("Configured Valet.\n")],
                    transactions: [
                        .mkdir("~/.config/valet"),
                        .write("", to: "/opt/homebrew/bin/valet"),
                        .write(
                            """
                            {
                              "paths": [
                                "/Users/fake/.config/valet/Sites"
                              ],
                              "tld": "test",
                              "loopback": "127.0.0.1"
                            }
                            """,
                            to: "~/.config/valet/config.json"
                        )
                    ]
                ),
                "/Users/fake/.composer/vendor/bin/valet trust": BatchFakeShellOutput(
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
                "cat /private/etc/sudoers.d/brew": .instant(""),
                "cat /private/etc/sudoers.d/valet": .instant("")
            ],
            files: [
                "/opt/homebrew/bin/brew": .fake(.binary),
                "/opt/homebrew/bin/composer": .fake(.binary),
                "/opt/homebrew/bin/php": .fake(.binary)
            ],
            privilegedCommandRunner: privilegedCommandRunner
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.completedSteps.contains(.valet))
        #expect(viewModel.action == .continueToStartup)
        #expect(
            viewModel.alertState
                == .valetSudoersCleanupFailed(
                    command: CommandCatalog.Onboarding.valetSudoersCleanupCommand
                )
        )
    }

    // The Homebrew step should copy the manual install command and wait for the user to
    // complete the installer in Terminal before the wizard checks again.
    @Test func requesting_homebrew_install_copies_command_and_waits_for_recheck() async {
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            shell: [
                CommandCatalog.Onboarding.homebrewInstall: BatchFakeShellOutput(
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
            hasCompletedIntroduction: true,
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
        #expect(viewModel.statusBannerSeverity == .info)
        #expect(viewModel.outputLines.contains(where: {
            $0.text.contains("onboarding_wizard.output.homebrew_command_copied".localized)
        }))
    }

    // After the user has run the copied Homebrew command, checking again should refresh the
    // toolchain state and advance the wizard into the PATH step.
    @Test func rechecking_homebrew_refreshes_progress_after_manual_install() async {
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            shell: [
                CommandCatalog.Onboarding.homebrewInstall: BatchFakeShellOutput(
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
            hasCompletedIntroduction: true,
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

    // If the .zshrc update command fails, auto-fix should fall back to the manual PATH
    // instructions instead of leaving the wizard on the automatic retry action.
    @Test func failed_automatic_path_fix_falls_back_to_manual_path_instructions() async {
        let container = makeOnboardingFakeContainer(
            architecture: "arm64",
            shell: [
                ZshRunCommand.append(
                    for: "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH"
                ): .instant(
                    "touch: ~/.zshrc: Permission denied\n",
                    .stdErr
                ),
                ZshRunCommand.append(
                    for: "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH"
                ): .instant(""),
                ZshRunCommand.append(
                    for: "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
                ): .instant(""),
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.action == .recheckPath)
        #expect(!viewModel.progress.pathConfigured)
        #expect(viewModel.commandLines == ShellEnvironment(container).pathInstructionLines())
        #expect(viewModel.showsStatusBanner)
        #expect(!viewModel.showsTerminalOutput)
        #expect(viewModel.statusBannerText == "onboarding_wizard.output.step_not_resolved".localized)
        #expect(viewModel.statusBannerSeverity == .warning)
    }

    // Manual PATH rechecks should use a plain status message instead of the terminal output panel.
    @Test func failed_manual_path_recheck_uses_status_banner() async {
        let container = makeOnboardingFakeContainer(
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
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        let task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.action == .recheckPath)
        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.showsStatusBanner)
        #expect(!viewModel.showsTerminalOutput)
        #expect(viewModel.statusBannerText == "onboarding_wizard.output.step_not_resolved".localized)
        #expect(viewModel.statusBannerSeverity == .warning)
    }

    // Starting the Command Line Tools installer should pause for manual completion instead of
    // auto-advancing; pressing Continue should re-check and alert if the tools are still missing.
    @Test func developer_tools_install_requires_manual_continue_before_rechecking() async {
        let container = makeOnboardingFakeContainer(
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
        let viewModel = OnboardingWizardViewModel(
            container: container,
            hasCompletedIntroduction: true,
            hasLoaded: true
        )

        var task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.action == .recheckDeveloperTools)
        #expect(viewModel.primaryButtonTitle == "onboarding_wizard.buttons.continue".localized)

        task = viewModel.performPrimaryAction()
        await task?.value

        #expect(viewModel.state == .waitingForManualCompletion)
        #expect(viewModel.alertState == .developerToolsIncomplete)
    }
}
// swiftlint:enable type_body_length file_length
