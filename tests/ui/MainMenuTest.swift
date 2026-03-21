//
//  MainMenuTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 03/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest

final class MainMenuTest: UITestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    final func test_can_open_status_menu_item() throws {
        let app = launch(openMenu: true)

        assertAllExist([
            // "Switch to PHP 8.4 (php)" should be visible since it is aliased to `php`
            app.menuItems["\("mi_php_switch".localized) 8.4 (php)"],
            // "Switch to PHP 8.1" should be the non-disabled option
            app.menuItems["\("mi_php_switch".localized) 8.3 (php@8.3)"],
            app.menuItems["\("mi_php_switch".localized) 8.2 (php@8.2)"],
            app.menuItems["\("mi_php_switch".localized) 8.1 (php@8.1)"],
            app.menuItems["\("mi_php_switch".localized) 8.0 (php@8.0)"],
            // We should see the about and quit items
            app.menuItems["mi_about".localized],
            app.menuItems["mi_quit".localized]
        ])

        // Wait briefly
        _ = app.menuItems["mi_about".localized].waitForExistence(timeout: 2.0)
    }

    final func test_can_open_domains_list() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_domain_list".localized).click()
    }

    final func test_can_open_php_doctor() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).hover()
        app.mainMenuItem(withText: "mi_fa_php_doctor".localized).click()
    }

    final func test_can_view_onboarding_flow() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).hover()
        app.mainMenuItem(withText: "mi_view_onboarding".localized).click()
    }

    final func test_can_open_command_history() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_other".localized).hover()
        app.mainMenuItem(withText: "mi_view_command_history".localized).click()

        assertExists(app.windows["command_history.title".localized], 2.0)

        Thread.sleep(forTimeInterval: 5)
    }

    final func test_can_open_about() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_about".localized).click()
    }

    final func test_can_open_config_editor() throws {
        let app = launch(openMenu: true)

        app.buttons["phpConfigButton"].click()

        Thread.sleep(forTimeInterval: 0.5)

        assertExists(app.staticTexts["confman.title".localized], 1)
    }

    final func test_can_open_settings() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_preferences".localized).click()

        Thread.sleep(forTimeInterval: 0.5)

        assertExists(app.buttons["General"])
        click(app.buttons["General"])

        assertExists(app.buttons["Appearance"])
        click(app.buttons["Appearance"])

        assertExists(app.buttons["Visibility"])
        click(app.buttons["Visibility"])

        assertExists(app.buttons["Notifications"])
        click(app.buttons["Notifications"])
    }

    final func test_can_open_php_version_manager() throws {
        let app = launch(openMenu: true)

        app.mainMenuItem(withText: "mi_php_version_manager".localized).click()

        // Should display loader
        assertExists(app.staticTexts["phpman.busy.title".localized], 1)

        // After loading, should display various versions
        assertExists(app.staticTexts["PHP 8.2"], 5)
        assertExists(app.staticTexts["PHP 8.3"])
        assertExists(app.staticTexts["PHP 8.4"])
        assertExists(app.staticTexts["PHP 8.5"])

        // Should also display pre-release version
        assertExists(app.staticTexts["PHP 8.6"])
        assertExists(app.staticTexts["phpman.version.prerelease".localized.uppercased()])
        assertExists(app.staticTexts["phpman.version.available_for_installation".localized])

        // The pre-release version should be unavailable
        assertExists(app.staticTexts["phpman.version.unavailable".localized])

        // But not PHP 8.7 or 9.0 yet
        assertNotExists(app.staticTexts["PHP 8.7"])
        assertNotExists(app.staticTexts["PHP 9.0"])

        // Also, PHP 8.4 should have an update available
        assertExists(app.staticTexts["phpman.version.has_update".localized(
            "8.4.5",
            "8.4.11"
        )], 5)
    }

    final func test_can_quit_app() throws {
        let app = launch(openMenu: true)
        app.mainMenuItem(withText: "mi_quit".localized).click()
    }

    /**
     Verifies that the ServicesView updates correctly when Homebrew service
     statuses change while the menu is open. On `menuWillOpen`, a background
     reload fetches fresh service data. If a service's status has changed
     (e.g. nginx stopped), the ServicesView should re-render to reflect this.
     */
    final func test_services_status_change_while_menu_open_does_not_crash() throws {
        // The sudo brew services command is called twice:
        //   1. During startup (Startup+Launch)
        //   2. On menuWillOpen (if >2s since last reload)
        //
        // Call 1 returns normal data and swaps the output via transaction,
        // so call 2 (while menu is open) returns nginx as stopped.
        let changedResponse = """
        [
            {"name":"dnsmasq","service_name":"homebrew.mxcl.dnsmasq","running":true,"loaded":true,"schedulable":false,"pid":122,"exit_code":0,"user":"root","status":"started","file":"/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist","command":"dnsmasq","working_dir":null,"root_dir":null,"log_path":null,"error_log_path":null,"interval":null,"cron":null},
            {"name":"nginx","service_name":"homebrew.mxcl.nginx","running":false,"loaded":true,"schedulable":false,"pid":null,"exit_code":0,"user":"root","status":"none","file":"/Library/LaunchDaemons/homebrew.mxcl.nginx.plist","command":"nginx","working_dir":null,"root_dir":null,"log_path":null,"error_log_path":null,"interval":null,"cron":null},
            {"name":"php","service_name":"homebrew.mxcl.php","running":true,"loaded":true,"schedulable":false,"pid":160,"exit_code":0,"user":"root","status":"started","file":"/Library/LaunchDaemons/homebrew.mxcl.php.plist","command":"php-fpm","working_dir":null,"root_dir":null,"log_path":null,"error_log_path":null,"interval":null,"cron":null}
        ]
        """

        // Configure our test case so the brew services update as noted above
        let cmd = "sudo /opt/homebrew/bin/brew services info --all --json"
        var config = TestableConfigurations.working
        config.shellOutput[cmd] = BatchFakeShellOutput(
            items: [
                .delayed(0.2, ShellStrings.shared.brewServicesAsRoot)
            ],
            transactions: [
                .shell(cmd, .delayed(4, changedResponse))
            ]
        )

        // Start the app
        let app = launch(openMenu: true, with: config)

        // Verify that all services are initially running
        assertExists(app.staticTexts["phpman.services.all_ok".localized], 3.0)

        // The menu is now open. The `menuWillOpen` delegate has fired an async
        // `reloadServicesStatus()` which will receive the changed response
        // where nginx is stopped. The ServicesView re-renders while the menu
        // is displayed.

        // Wait for the async reload to complete and layout to settle.
        Thread.sleep(forTimeInterval: 4)

        // Verify the app is still running and responsive
        assertExists(app.menuItems["mi_about".localized], 1.0)

        // Verify that the services status actually changed (nginx is now stopped)
        assertExists(app.staticTexts["phpman.services.inactive".localized], 1.0)
    }
}
