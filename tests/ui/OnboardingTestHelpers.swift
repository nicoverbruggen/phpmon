//
//  OnboardingTestHelpers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

extension OnboardingTest {
    func launchOnboardingWizard(with scenario: OnboardingScenario) -> XCPMApplication {
        var configuration = TestableConfigurations.working
        configuration.prepareFreshCoreOnboardingSystem()
        configuration.mockRequiredOnboardingInstallCommands()
        scenario.apply(to: &configuration)

        return launch(
            waitForInitialization: false,
            with: configuration
        )
    }

    func assertWizardOpenedInsteadOfStartupAlert(_ app: XCPMApplication) {
        assertAllExist([
            app.staticTexts["onboarding_wizard.title".localized],
            app.buttons["onboarding_wizard.buttons.start_setup".localized],
            app.buttons["onboarding_wizard.buttons.skip".localized]
        ], 3.0)
        assertNotExists(app.dialogs["generic.notice".localized], 1.0)
    }

    func startWizard(_ app: XCPMApplication) {
        click(app.buttons["onboarding_wizard.buttons.start_setup".localized])
    }

    func installDeveloperTools(_ app: XCPMApplication) {
        assertExists(app.links["onboarding_wizard.buttons.learn_more".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.continue".localized])
    }

    func completeRequiredInstallFlow(_ app: XCPMApplication) {
        advanceToValetStep(app)
        completeValetAndFinish(app)

        app.terminate()
    }

    func advanceToPhpComposerStep(_ app: XCPMApplication) {
        let installPhpComposerButton = app.buttons["onboarding_wizard.buttons.install_php_composer".localized]

        if installPhpComposerButton.waitForExistence(timeout: 1.0) {
            return
        }

        installHomebrew(app)
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(installPhpComposerButton, 3.0)
    }

    func advanceToValetStep(_ app: XCPMApplication) {
        advanceToPhpComposerStep(app)
        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)
    }

    func completeValetAndFinish(_ app: XCPMApplication) {
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
        approvePrivilegedCommand(app)
        approvePrivilegedCommand(app)
        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.continue".localized])
        waitForMenu(app)
    }

    func skipValetAndContinueInStandaloneMode(_ app: XCPMApplication) {
        assertExists(app.buttons["onboarding_wizard.buttons.skip_valet".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.skip_valet".localized])

        let skipValetConfirmationButton = app.sheets.buttons[
            "onboarding_wizard.skip_valet_confirmation.confirm".localized
        ]
        assertExists(skipValetConfirmationButton, 3.0)
        click(skipValetConfirmationButton)

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.continue".localized])
        waitForMenu(app)
    }

    func installHomebrew(_ app: XCPMApplication) {
        assertExists(app.staticTexts["onboarding_wizard.command.homebrew.title".localized], 3.0)
        assertExists(app.links["onboarding_wizard.buttons.learn_more".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.copy_command".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.copy_command".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.check_again".localized])
    }

    func assertManualPathInstructions(_ app: XCPMApplication) {
        assertExists(app.staticTexts["onboarding_wizard.command.path.title".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        assertNotExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 1.0)
    }

    func assertIntroductionMarksCompletedSteps(_ app: XCPMApplication, count: Int) {
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "onboarding_wizard.badges.completed".localized).count,
            count
        )
    }

    func approvePrivilegedCommand(_ app: XCPMApplication) {
        assertExists(app.buttons["PrivilegedCommandApproveButton"], 3.0)
        click(app.buttons["PrivilegedCommandApproveButton"])
    }

    func denyPrivilegedCommand(_ app: XCPMApplication) {
        assertExists(app.buttons["PrivilegedCommandDenyButton"], 3.0)
        click(app.buttons["PrivilegedCommandDenyButton"])
    }
}

enum OnboardingScenario {
    case developerToolsAlreadyInstalled
    case developerToolsMissing
    case firstLaunchPartialSetup
    case manualPathFixRequired

    func apply(to configuration: inout TestableConfiguration) {
        switch self {
        case .developerToolsAlreadyInstalled:
            break
        case .developerToolsMissing:
            configuration.mockDeveloperToolsInstall()
        case .firstLaunchPartialSetup:
            configuration.mockFirstLaunchPartialSetup()
        case .manualPathFixRequired:
            configuration.configuredShell = "/bin/bash"
        }
    }
}

private extension TestableConfiguration {
    mutating func prepareFreshCoreOnboardingSystem() {
        internalStatsOverrides[InternalStats.launchCount.rawValue] = 0
        filesystem["/opt/homebrew/bin/brew"] = nil
        filesystem["/opt/homebrew/bin/php"] = nil
        filesystem["/usr/local/bin/composer"] = nil
        filesystem["/opt/homebrew/bin/composer"] = nil
        filesystem["/opt/homebrew/bin/valet"] = nil
        filesystem["/Users/fake/.composer/vendor/bin/valet"] = nil
        filesystem["~/.config/valet"] = nil
        filesystem["~/.config/valet/config.json"] = nil
        shellOutput["ls /opt/homebrew/opt | grep php"] = .instant("")
        shellOutput["cat /private/etc/sudoers.d/brew"] = .instant("")
        shellOutput["cat /private/etc/sudoers.d/valet"] = .instant("")
    }

    mutating func mockRequiredOnboardingInstallCommands() {
        shellOutput[homebrewInstallCommand()] = BatchFakeShellOutput(
            items: [.instant("Installed Homebrew.\n")],
            transactions: [
                .write("", to: "/opt/homebrew/bin/brew")
            ]
        )
        shellOutput[zshPathCommand(phpMonitorPathLine())] = .instant("")
        shellOutput[zshPathCommand(composerPathLine())] = .instant("")
        shellOutput[zshPathCommand(homebrewPathLine())] = BatchFakeShellOutput(
            items: [.instant("")],
            transactions: [
                .appendPathEntries([
                    "/usr/local/bin",
                    "/usr/bin",
                    "/bin",
                    "/usr/sbin",
                    "/Users/fake/.config/phpmon/bin",
                    "/Users/fake/.composer/vendor/bin",
                    "/opt/homebrew/bin"
                ])
            ]
        )
        shellOutput["/opt/homebrew/bin/brew tap shivammathur/php"] = .instant("Tapped shivammathur/php.\n")
        shellOutput["/opt/homebrew/bin/brew tap shivammathur/extensions"] = .instant("Tapped shivammathur/extensions.\n")
        shellOutput["/opt/homebrew/bin/brew install php composer"] = BatchFakeShellOutput(
            items: [.instant("Installed PHP and Composer.\n")],
            transactions: [
                .write("", to: "/opt/homebrew/bin/php"),
                .write("", to: "/opt/homebrew/bin/composer"),
                .shell("ls /opt/homebrew/opt | grep php", .instant("php\n"))
            ]
        )
        shellOutput["/opt/homebrew/bin/composer global require laravel/valet"] = BatchFakeShellOutput(
            items: [.instant("Installed Valet.\n")],
            transactions: [
                .write("", to: "/Users/fake/.composer/vendor/bin/valet")
            ]
        )
        shellOutput["/opt/homebrew/bin/brew install dnsmasq nginx"] = .instant("Installed dnsmasq and nginx.\n")
        shellOutput["/Users/fake/.composer/vendor/bin/valet install"] = BatchFakeShellOutput(
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
        )
        shellOutput["/Users/fake/.composer/vendor/bin/valet trust"] = BatchFakeShellOutput(
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
        )
    }

    mutating func mockDeveloperToolsInstall() {
        shellOutput["/usr/bin/xcode-select -p"] = .instant(
            """
            xcode-select: error: Unable to get active developer directory. Use `sudo xcode-select --switch path/to/Xcode.app` to set one (or see `man xcode-select`)
            """,
            .stdErr
        )
        shellOutput["/usr/bin/xcode-select --install"] = BatchFakeShellOutput(
            items: [
                .instant("xcode-select: note: install requested for command line developer tools")
            ],
            transactions: [
                .shell(
                    "/usr/bin/xcode-select -p",
                    .instant("/Library/Developer/CommandLineTools\n")
                )
            ]
        )
    }

    mutating func mockFirstLaunchPartialSetup() {
        filesystem["/opt/homebrew/bin/brew"] = .fake(.binary)
        filesystem["/opt/homebrew/opt/nginx"] = .fake(.directory)
        internalStatsOverrides[InternalStats.launchCount.rawValue] = 0
        shellPath = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/Users/fake/.config/phpmon/bin",
            "/Users/fake/.composer/vendor/bin",
            "/opt/homebrew/bin"
        ].joined(separator: ":")
    }

    private func homebrewInstallCommand() -> String {
        return #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#
    }

    private func composerPathLine() -> String {
        return "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH"
    }

    private func phpMonitorPathLine() -> String {
        return "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH"
    }

    private func homebrewPathLine() -> String {
        return "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
    }

    private func zshPathCommand(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "'", with: "'\\''")

        return """
            touch ~/.zshrc && \
            grep -qxF '\(escaped)' ~/.zshrc \
            || printf '%s\\n' '\(escaped)' >> ~/.zshrc
        """
    }
}
