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

    override func tearDownWithError() throws {}

    // If Command Line Tools already exist, the wizard should acknowledge step 1 and continue through
    // the mocked Homebrew, PATH, and PHP/Composer setup before regular startup enables the menu.
    final func test_launch_runs_onboarding_wizard_flow_when_developer_tools_are_already_installed() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        completeRequiredInstallFlow(app)
    }

    // If Command Line Tools are missing, the wizard should request their installation first and only
    // continue through the rest of setup once the mocked system command reports them as installed.
    final func test_launch_runs_onboarding_wizard_flow_that_installs_developer_tools() throws {
        let app = launchOnboardingWizard(with: .developerToolsMissing)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        installDeveloperTools(app)
        completeRequiredInstallFlow(app)
    }

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

    // Users can skip the optional Valet step, confirm Standalone Mode, and still finish
    // onboarding successfully without being forced through Valet installation.
    final func test_launch_can_skip_valet_and_continue_in_standalone_mode() throws {
        let app = launchOnboardingWizard(with: .developerToolsAlreadyInstalled)

        assertWizardOpenedInsteadOfStartupAlert(app)
        startWizard(app)
        installHomebrew(app)
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
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
        installHomebrew(app)
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)

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
        installHomebrew(app)
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
        approvePrivilegedCommand(app)
        denyPrivilegedCommand(app)

        assertExists(app.staticTexts["onboarding_wizard.alert.valet_sudoers_cleanup_failed.title".localized], 3.0)
        assertExists(app.buttons["generic.ok".localized], 3.0)
        click(app.buttons["generic.ok".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)

        app.terminate()
    }

    private func launchOnboardingWizard(with scenario: OnboardingScenario) -> XCPMApplication {
        var configuration = TestableConfigurations.working
        configuration.prepareFreshCoreOnboardingSystem()
        configuration.mockRequiredOnboardingInstallCommands()
        scenario.apply(to: &configuration)

        return launch(
            waitForInitialization: false,
            with: configuration
        )
    }

    private func assertWizardOpenedInsteadOfStartupAlert(_ app: XCPMApplication) {
        assertAllExist([
            app.staticTexts["onboarding_wizard.title".localized],
            app.buttons["onboarding_wizard.buttons.start_setup".localized],
            app.buttons["onboarding_wizard.buttons.skip".localized]
        ], 3.0)
        assertNotExists(app.dialogs["generic.notice".localized], 1.0)
    }

    private func startWizard(_ app: XCPMApplication) {
        click(app.buttons["onboarding_wizard.buttons.start_setup".localized])
    }

    private func installDeveloperTools(_ app: XCPMApplication) {
        assertExists(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.continue".localized])
    }

    private func completeRequiredInstallFlow(_ app: XCPMApplication) {
        installHomebrew(app)
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
        approvePrivilegedCommand(app)
        approvePrivilegedCommand(app)
        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)

        click(app.buttons["onboarding_wizard.buttons.continue".localized])
        waitForMenu(app)

        app.terminate()
    }

    private func installHomebrew(_ app: XCPMApplication) {
        assertExists(app.staticTexts["onboarding_wizard.command.homebrew.title".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.copy_command".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.copy_command".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.check_again".localized])
    }

    private func assertManualPathInstructions(_ app: XCPMApplication) {
        assertExists(app.staticTexts["onboarding_wizard.command.path.title".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        assertNotExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 1.0)
    }

    private func approvePrivilegedCommand(_ app: XCPMApplication) {
        assertExists(app.buttons["PrivilegedCommandApproveButton"], 3.0)
        click(app.buttons["PrivilegedCommandApproveButton"])
    }

    private func denyPrivilegedCommand(_ app: XCPMApplication) {
        assertExists(app.buttons["PrivilegedCommandDenyButton"], 3.0)
        click(app.buttons["PrivilegedCommandDenyButton"])
    }
}

fileprivate enum OnboardingScenario {
    case developerToolsAlreadyInstalled
    case developerToolsMissing
    case manualPathFixRequired

    func apply(to configuration: inout TestableConfiguration) {
        switch self {
        case .developerToolsAlreadyInstalled:
            break
        case .developerToolsMissing:
            configuration.mockDeveloperToolsInstall()
        case .manualPathFixRequired:
            configuration.configuredShell = "/bin/bash"
        }
    }
}

fileprivate extension TestableConfiguration {
    mutating func prepareFreshCoreOnboardingSystem() {
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
        shellOutput["/opt/homebrew/bin/valet trust"] = BatchFakeShellOutput(
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
