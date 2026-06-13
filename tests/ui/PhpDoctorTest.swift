//
//  PHPDoctorTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/06/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

final class PHPDoctorTest: UITestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    final func test_php_doctor_shows_no_warnings_for_quiet_environment() throws {
        let app = launchPhpDoctor(with: phpDoctorConfiguration())

        assertExists(app.staticTexts["warnings.none".localized], 3.0)
        assertWarningIsNotVisible("warnings.arm_compatibility.title", in: app)
        assertWarningIsNotVisible("warnings.helper_permissions.title", in: app)
        assertWarningIsNotVisible("warnings.invalid_shell.title", in: app)
        assertWarningIsNotVisible("warnings.xdebug_conf_missing.title", in: app)
        assertWarningIsNotVisible("warnings.required_taps_missing.title", in: app)
        assertWarningIsNotVisible("warnings.required_taps_untrusted.title", in: app)
        assertWarningIsNotVisible("warnings.files_missing.title", in: app)
        assertWarningIsNotVisible("warnings.certificates_expired.title", in: app)
    }

    final func test_php_doctor_warns_about_rosetta_without_automatic_fix() throws {
        var configuration = phpDoctorConfiguration()
        configuration.shellOutput["sysctl -n sysctl.proc_translated"] = .instant("1")

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.arm_compatibility.title", in: app)
        assertNotExists(app.buttons["Fix Automatically"], 1.0)
        assertExists(app.buttons["Learn More"], 1.0)
    }

    final func test_php_doctor_warns_about_unavailable_helpers_and_fix_updates_path() throws {
        var configuration = phpDoctorConfiguration()
        configuration.shellPath = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/opt/homebrew/bin"
        ].joined(separator: ":")
        configuration.shellOutput[zshPathCommand(phpMonitorPathLine())] = BatchFakeShellOutput(
            items: [.instant("")],
            transactions: [
                .write(phpMonitorPathLine(), to: "~/.zshrc"),
                .appendPathEntries(["/Users/fake/.config/phpmon/bin"])
            ]
        )

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.helper_permissions.title", in: app)
        clickAutomaticFix(in: app)
        assertWarningDisappears("warnings.helper_permissions.title", in: app, timeout: 5.0)
        assertExists(app.staticTexts["warnings.none".localized], 5.0)
    }

    final func test_php_doctor_warns_about_invalid_shell_without_automatic_fix() throws {
        var configuration = phpDoctorConfiguration()
        configuration.configuredShell = "/bin/this_shell_does_not_exist"

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.invalid_shell.title", in: app)
        assertNotExists(app.buttons["Fix Automatically"], 1.0)
    }

    final func test_php_doctor_warns_about_xdebug_configuration_and_fix_updates_ini() throws {
        var configuration = phpDoctorConfiguration()
        configuration.filesystem["/opt/homebrew/etc/php/8.4/conf.d/ext-xdebug.ini"] = .fake(
            .text,
            "zend_extension=xdebug.so"
        )
        configuration.shellOutput["/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"] = .instant("""
        /opt/homebrew/etc/php/8.4/conf.d/php-memory-limits.ini
        /opt/homebrew/etc/php/8.4/conf.d/ext-xdebug.ini
        """)

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.xdebug_conf_missing.title", in: app)
        clickAutomaticFix(in: app)
        assertWarningDisappears("warnings.xdebug_conf_missing.title", in: app, timeout: 5.0)
        assertExists(app.staticTexts["warnings.none".localized], 5.0)
    }

    final func test_php_doctor_warns_about_missing_required_taps_and_fix_taps_them() throws {
        var configuration = phpDoctorConfiguration()
        configuration.shellOutput["/opt/homebrew/bin/brew tap"] = .instant("""
        homebrew/cask
        homebrew/core
        homebrew/services
        nicoverbruggen/cask
        """)
        configuration.shellOutput["/opt/homebrew/bin/brew help trust"] = .instant(
            "Error: Unknown command: trust\n",
            .stdErr
        )
        configuration.shellOutput["/opt/homebrew/bin/brew tap shivammathur/php"] = BatchFakeShellOutput(
            items: [.instant("Tapped shivammathur/php.\n")],
            transactions: [
                .shell(
                    "/opt/homebrew/bin/brew tap",
                    .instant("""
                    homebrew/cask
                    homebrew/core
                    homebrew/services
                    nicoverbruggen/cask
                    shivammathur/php
                    """)
                )
            ]
        )
        configuration.shellOutput["/opt/homebrew/bin/brew tap shivammathur/extensions"] = BatchFakeShellOutput(
            items: [.instant("Tapped shivammathur/extensions.\n")],
            transactions: [
                .shell(
                    "/opt/homebrew/bin/brew tap",
                    .instant("""
                    homebrew/cask
                    homebrew/core
                    homebrew/services
                    nicoverbruggen/cask
                    shivammathur/php
                    shivammathur/extensions
                    """)
                )
            ]
        )

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.required_taps_missing.title", in: app)
        assertWarningIsNotVisible("warnings.required_taps_untrusted.title", in: app)
        clickAutomaticFix(in: app)
        assertWarningDisappears("warnings.required_taps_missing.title", in: app, timeout: 5.0)
        assertExists(app.staticTexts["warnings.none".localized], 5.0)
    }

    final func test_php_doctor_warns_about_untrusted_required_taps_and_fix_trusts_them() throws {
        var configuration = phpDoctorConfiguration()
        configuration.shellOutput["/opt/homebrew/bin/brew trust --tap"] = .instant("""
        All official taps and commands are trusted.
        Trusted taps:
          shivammathur/php
        """)
        configuration.shellOutput["/opt/homebrew/bin/brew trust --tap shivammathur/extensions"] = BatchFakeShellOutput(
            items: [.instant("Trusted tap: shivammathur/extensions\n")],
            transactions: [
                .shell(
                    "/opt/homebrew/bin/brew trust --tap",
                    .instant("""
                    All official taps and commands are trusted.
                    Trusted taps:
                      shivammathur/php
                      shivammathur/extensions
                    """)
                )
            ]
        )

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.required_taps_untrusted.title", in: app)
        assertWarningIsNotVisible("warnings.required_taps_missing.title", in: app)
        clickAutomaticFix(in: app)
        assertWarningDisappears("warnings.required_taps_untrusted.title", in: app, timeout: 5.0)
        assertExists(app.staticTexts["warnings.none".localized], 5.0)
    }

    final func test_php_doctor_warns_about_missing_php_configuration_without_automatic_fix() throws {
        var configuration = phpDoctorConfiguration()
        configuration.filesystem["/opt/homebrew/etc/php/8.4/php.ini"] = nil

        let app = launchPhpDoctor(with: configuration)

        assertWarningIsVisible("warnings.files_missing.title", in: app)
        assertNotExists(app.buttons["Fix Automatically"], 1.0)
    }

    final func test_php_doctor_warns_about_expired_certificates_and_fix_renews_them() throws {
        let app = launchPhpDoctor(
            with: phpDoctorConfiguration(),
            environment: ["PHPMON_FAKE_EXPIRED_CERTIFICATES": "1"]
        )

        assertWarningIsVisible("warnings.certificates_expired.title", in: app)
        clickAutomaticFix(in: app)

        assertExists(app.windows["domain_list.title".localized], 5.0)
        assertExists(app.staticTexts["cert_alert.title".localized], 5.0)
        click(app.buttons["cert_alert.renew".localized])
        assertWarningDisappears("warnings.certificates_expired.title", in: app, timeout: 8.0)
    }

    final func test_php_doctor_can_render_all_warning_definitions() throws {
        let app = launchPhpDoctor(
            with: phpDoctorConfiguration(),
            environment: ["EXTREME_DOCTOR_MODE": "1"]
        )

        assertWarningIsVisible("warnings.arm_compatibility.title", in: app)
        assertWarningIsVisible("warnings.helper_permissions.title", in: app)
        assertWarningIsVisible("warnings.invalid_shell.title", in: app)
        assertWarningIsVisible("warnings.xdebug_conf_missing.title", in: app)
        assertWarningIsVisible("warnings.required_taps_missing.title", in: app)
        assertWarningIsVisible("warnings.required_taps_untrusted.title", in: app)
        assertWarningIsVisible("warnings.files_missing.title", in: app)
        assertWarningIsVisible("warnings.certificates_expired.title", in: app)
    }

    private func launchPhpDoctor(
        with configuration: TestableConfiguration,
        environment: [String: String] = [:]
    ) -> XCPMApplication {
        let app = XCPMApplication()
        app.withConfiguration(configuration)
        app.launchEnvironment = environment
        app.launch()

        waitForMenu(app, openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).hover()
        app.mainMenuItem(withText: "mi_fa_php_doctor".localized).click()

        return app
    }

    private func assertWarningIsVisible(
        _ localizationKey: String,
        in app: XCPMApplication,
        timeout: TimeInterval = 3.0
    ) {
        assertExists(app.staticTexts[localizationKey.localized], timeout)
    }

    private func assertWarningIsNotVisible(
        _ localizationKey: String,
        in app: XCPMApplication,
        timeout: TimeInterval = 1.0
    ) {
        assertNotExists(app.staticTexts[localizationKey.localized], timeout)
    }

    private func assertWarningDisappears(
        _ localizationKey: String,
        in app: XCPMApplication,
        timeout: TimeInterval
    ) {
        let element = app.staticTexts[localizationKey.localized]
        let predicate = NSPredicate(format: "exists == false")
        let expectation = expectation(for: predicate, evaluatedWith: element, handler: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result == .timedOut {
            XCTFail("Expected warning to disappear: \(localizationKey.localized)")
        }
    }

    private func clickAutomaticFix(in app: XCPMApplication) {
        let button = app.buttons["Fix Automatically"].firstMatch
        assertExists(button, 3.0)
        click(button)
    }

    private func phpDoctorConfiguration() -> TestableConfiguration {
        var configuration = TestableConfigurations.working
        configuration.shellPath = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/Users/fake/.config/phpmon/bin",
            "/Users/fake/.composer/vendor/bin",
            "/opt/homebrew/bin"
        ].joined(separator: ":")
        configuration.filesystem["/opt/homebrew/etc/php/8.4/php-fpm.conf"] = .fake(.text)
        configuration.shellOutput["ls /opt/homebrew/opt | grep php@"] = .instant("")
        configuration.shellOutput["/opt/homebrew/bin/brew tap"] = .instant("""
        homebrew/cask
        homebrew/core
        homebrew/services
        nicoverbruggen/cask
        shivammathur/php
        shivammathur/extensions
        """)
        configuration.shellOutput["/opt/homebrew/bin/brew trust --tap"] = .instant("""
        All official taps and commands are trusted.
        Trusted taps:
          shivammathur/php
          shivammathur/extensions
        """)
        return configuration
    }

    private func phpMonitorPathLine() -> String {
        return "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH"
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
