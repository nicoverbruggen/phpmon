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
            app.buttons["onboarding_wizard.buttons.quit".localized]
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
        shellOutput["ls /opt/homebrew/opt | grep php"] = .instant("")
    }

    mutating func mockRequiredOnboardingInstallCommands() {
        shellOutput[homebrewInstallCommand()] = BatchFakeShellOutput(
            items: [.instant("Installed Homebrew.\n")],
            transactions: [
                .write("", to: "/opt/homebrew/bin/brew")
            ]
        )
        shellOutput[zshPathCommand(composerPathLine())] = .instant("")
        shellOutput[zshPathCommand(homebrewPathLine())] = BatchFakeShellOutput(
            items: [.instant("")],
            transactions: [
                .appendPathEntries([
                    "/usr/local/bin",
                    "/usr/bin",
                    "/bin",
                    "/usr/sbin",
                    "/Users/fake/.composer/vendor/bin",
                    "/opt/homebrew/bin"
                ])
            ]
        )
        shellOutput["/opt/homebrew/bin/brew install php composer"] = BatchFakeShellOutput(
            items: [.instant("Installed PHP and Composer.\n")],
            transactions: [
                .write("", to: "/opt/homebrew/bin/php"),
                .write("", to: "/opt/homebrew/bin/composer"),
                .shell("ls /opt/homebrew/opt | grep php", .instant("php\n"))
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

    private func homebrewPathLine() -> String {
        return "export PATH=$HOME/bin:/opt/homebrew/bin:$PATH"
    }

    private func zshPathCommand(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "'", with: "'\\''")

        return """
            touch ~/.zshrc && \
            grep -qxF '\(escaped)' ~/.zshrc \
            || echo '\n\n\(escaped)\n' >> ~/.zshrc
        """
    }
}
