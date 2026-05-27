//
//  OnboardingTestHelpers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

extension OnboardingTest {
    func onboardingFlow(with scenario: OnboardingScenario) -> OnboardingTestFlow {
        return OnboardingTestFlow(testCase: self, scenario: scenario)
    }
}

final class OnboardingTestFlow {
    let app: XCPMApplication

    private let testCase: UITestCase

    init(testCase: UITestCase, scenario: OnboardingScenario) {
        self.testCase = testCase

        var configuration = TestableConfigurations.working
        configuration.prepareFreshCoreOnboardingSystem()
        configuration.mockRequiredOnboardingInstallCommands()
        configuration.allowsDelayedShellCommands = true
        scenario.apply(to: &configuration)

        self.app = testCase.launch(
            waitForInitialization: false,
            with: configuration
        )
    }

    func assertDidOpenWizard() {
        testCase.assertAllExist([
            app.staticTexts["onboarding_wizard.title".localized],
            app.buttons["onboarding_wizard.buttons.start_setup".localized],
            app.buttons["onboarding_wizard.buttons.skip".localized]
        ], 3.0)
        testCase.assertNotExists(app.dialogs["generic.notice".localized], 1.0)
    }

    func assertIntroStepsComplete(count: Int) {
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "onboarding_wizard.badges.completed".localized).count,
            count
        )
    }

    func startWizard() {
        click(app.buttons["onboarding_wizard.buttons.start_setup".localized])
    }

    func installDeveloperTools() {
        assertExists(app.links["onboarding_wizard.buttons.learn_more".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.install_developer_tools".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.continue".localized])
    }

    func installHomebrew() {
        assertExists(app.staticTexts["onboarding_wizard.command.homebrew.title".localized], 3.0)
        assertExists(app.links["onboarding_wizard.buttons.learn_more".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.copy_command".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.copy_command".localized])

        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.check_again".localized])
    }

    func configurePathAutomatically() {
        assertExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.fix_path".localized])
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)
    }

    func beginPhpInstall() {
        assertExists(app.buttons["onboarding_wizard.buttons.install_php_composer".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.install_php_composer".localized])
    }

    func installPhp() {
        beginPhpInstall()
        assertTerminalOutputContains("==> Fetching php and composer formulae...")
        assertValetInstallIsAvailable(timeout: 5.0)
    }

    func beginValetInstall() {
        assertValetInstallIsAvailable()
        click(app.buttons["onboarding_wizard.buttons.install_valet".localized])
    }

    func installValet() {
        beginValetInstall()
        testCase.approvePrivilegedCommand(in: app)
        assertTerminalOutputContains("Updating global composer dependencies...")
        assertTerminalOutputContains("Fetching dnsmasq and nginx formulae")
        assertTerminalOutputContains("Updating Valet configuration...")
        testCase.approvePrivilegedCommand(in: app)
        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 4.0)
    }

    func skipValet() {
        assertExists(app.buttons["onboarding_wizard.buttons.skip_valet".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.skip_valet".localized])

        let skipValetConfirmationButton = app.sheets.buttons[
            "onboarding_wizard.skip_valet_confirmation.confirm".localized
        ]
        assertExists(skipValetConfirmationButton, 3.0)
        click(skipValetConfirmationButton)
        assertContinueButtonIsAvailable()
    }

    func continueToMenu() {
        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
        click(app.buttons["onboarding_wizard.buttons.continue".localized])
        testCase.waitForMenu(app)
    }

    func assertManualPathInstructions() {
        assertExists(app.staticTexts["onboarding_wizard.command.path.title".localized], 3.0)
        assertExists(app.buttons["onboarding_wizard.buttons.check_again".localized], 3.0)
        assertNotExists(app.buttons["onboarding_wizard.buttons.fix_path".localized], 1.0)
    }

    func recheckManualPath() {
        assertManualPathInstructions()
        click(app.buttons["onboarding_wizard.buttons.check_again".localized])
    }

    func assertValetInstallIsAvailable(timeout: TimeInterval = 3.0) {
        assertExists(app.buttons["onboarding_wizard.buttons.install_valet".localized], timeout)
    }

    func assertPhpInstallIsReadyForRetry() {
        let installButton = app.buttons["onboarding_wizard.buttons.install_php_composer".localized]
        assertExists(installButton, 3.0)

        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: installButton)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(result, .completed)
    }

    func assertContinueButtonIsAvailable() {
        assertExists(app.buttons["onboarding_wizard.buttons.continue".localized], 3.0)
    }

    func assertContinueButtonIsUnavailable() {
        assertNotExists(app.buttons["onboarding_wizard.buttons.continue".localized], 1.0)
    }

    func assertSkipSetupIsDisabled() {
        let skipSetupButton = app.buttons["onboarding_wizard.buttons.skip".localized]
        assertExists(skipSetupButton, 3.0)

        let predicate = NSPredicate(format: "isEnabled == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: skipSetupButton)
        let result = XCTWaiter().wait(for: [expectation], timeout: 3.0)

        XCTAssertEqual(result, .completed)
    }

    func assertCleanupWarningIsVisible() {
        assertExists(app.staticTexts["onboarding_wizard.alert.valet_sudoers_cleanup_failed.title".localized], 3.0)
        assertExists(app.buttons["generic.ok".localized], 3.0)
    }

    func assertWarningStatusBanner(text: String) {
        let statusBanner = app.staticTexts["OnboardingStatusBanner"]
        assertExists(statusBanner, 3.0)
        XCTAssertEqual(statusBanner.label, text)
        XCTAssertEqual(statusBanner.value as? String, "warning")
    }

    func dismissCleanupWarning() {
        click(app.buttons["generic.ok".localized])
    }

    func approvePrivilegedCommand() {
        testCase.approvePrivilegedCommand(in: app)
    }

    func denyPrivilegedCommand() {
        testCase.denyPrivilegedCommand(in: app)
    }

    func terminate() {
        app.terminate()
    }

    private func assertExists(_ element: XCUIElement, _ timeout: TimeInterval = 0.05) {
        testCase.assertExists(element, timeout)
    }

    private func assertNotExists(_ element: XCUIElement, _ timeout: TimeInterval = 0.05) {
        testCase.assertNotExists(element, timeout)
    }

    private func click(_ element: XCUIElement) {
        testCase.click(element)
    }

    func assertTerminalOutputContains(_ text: String, timeout: TimeInterval = 5.0) {
        let terminalOutput = app.textViews["OnboardingTerminalOutputText"]
        assertExists(terminalOutput, timeout)

        let predicate = NSPredicate(format: "value CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: terminalOutput)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(result, .completed)
    }
}

enum OnboardingScenario {
    case developerToolsAlreadyInstalled
    case developerToolsMissing
    case firstLaunchPartialSetup
    case manualPathFixRequired
    case phpComposerInstallFailsWithTerminalOutput

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
        case .phpComposerInstallFailsWithTerminalOutput:
            configuration.mockPhpComposerInstallFailure()
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
            items: [
                .delayed(0.2, "==> Fetching php and composer formulae...\n"),
                .delayed(0.2, "==> Downloading php manifest...\n"),
                .delayed(0.2, "==> Downloading composer manifest...\n"),
                .delayed(0.2, "==> Pouring php bottle...\n"),
                .delayed(0.2, "==> Pouring composer bottle...\n"),
                .delayed(0.2, "==> Caveats\n"),
                .delayed(2.0, "Installed PHP and Composer.\n")
            ],
            transactions: [
                .write("", to: "/opt/homebrew/bin/php"),
                .write("", to: "/opt/homebrew/bin/composer"),
                .shell("ls /opt/homebrew/opt | grep php", .instant("php\n"))
            ]
        )
        shellOutput["/opt/homebrew/bin/composer global require laravel/valet"] = BatchFakeShellOutput(
            items: [
                .delayed(0.2, "Updating global composer dependencies...\n"),
                .delayed(0.2, "Composer is installing laravel/valet...\n"),
                .delayed(2.0, "Installed Valet.\n")
            ],
            transactions: [
                .write("", to: "/Users/fake/.composer/vendor/bin/valet")
            ]
        )
        shellOutput["/opt/homebrew/bin/brew install dnsmasq nginx"] = BatchFakeShellOutput(items: [
            .delayed(0.2, "==> Fetching dnsmasq and nginx formulae...\n"),
            .delayed(0.2, "==> Downloading dnsmasq manifest...\n"),
            .delayed(0.2, "==> Downloading nginx manifest...\n"),
            .delayed(0.2, "==> Pouring dnsmasq bottle...\n"),
            .delayed(0.2, "==> Pouring nginx bottle...\n"),
            .delayed(2.0, "==> Done.\n")
        ])
        shellOutput["/Users/fake/.composer/vendor/bin/valet install"] = BatchFakeShellOutput(
            items: [
                .delayed(0.5, "Updating Valet configuration...\n"),
                .delayed(2.0, "Configured Valet.\n")
            ],
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

    mutating func mockPhpComposerInstallFailure() {
        shellOutput["/opt/homebrew/bin/brew install php composer"] = BatchFakeShellOutput(items: [
            .delayed(0.2, "==> Fetching php and composer formulae...\n"),
            .delayed(0.2, "Error: Simulated PHP install failure\n", .stdErr)
        ])
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
