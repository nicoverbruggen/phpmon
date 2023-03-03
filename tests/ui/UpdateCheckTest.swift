//
//  UpdateCheckTest.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 13/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

final class UpdateCheckTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    final func test_can_check_for_updates_with_no_new_update() throws {
        let app = launch(openMenu: true)
        app.menuItems["mi_check_for_updates".localized].click()

        assertExists(app.staticTexts["updater.alerts.is_latest_version.title".localized], 1.0)
        assertExists(app.buttons["generic.ok".localized])
    }

    final func test_will_prompt_at_launch_new_version_available() throws {
        var configuration = TestableConfigurations.working

        // Ensure automatic check is enabled
        configuration.preferenceOverrides[.automaticBackgroundUpdateCheck] = true

        // Ensure an update is available
        configuration.shellOutput[
            "curl -s --max-time 10 '\(Constants.Urls.DevBuildCaskFile.absoluteString)'"
        ] = .delayed(0.5, """
            cask 'phpmon-dev' do
                depends_on formula: 'gnu-sed'

                version '99.0.0_9999'
                sha256 '1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a'

                url 'https://github.com/nicoverbruggen/phpmon/releases/download/v99.0/phpmon-dev.zip'
                appcast 'https://github.com/nicoverbruggen/phpmon/releases.atom'
                name 'PHP Monitor DEV'
                homepage 'https://phpmon.app'

                app 'PHP Monitor DEV.app', target: "PHP Monitor DEV.app"
            end
            """)

        let app = launch(openMenu: false, with: configuration)

        // Expect to see the content of the appropriate alert box
        assertExists(app.staticTexts["updater.alerts.newer_version_available.title".localized("99.0.0 (9999)")], 2)
        assertExists(app.buttons["updater.alerts.buttons.install".localized])
        assertExists(app.buttons["updater.alerts.buttons.dismiss".localized])
    }

    final func test_will_require_manual_search_for_update() throws {
        var configuration = TestableConfigurations.working

        // Ensure automatic check is disabled
        configuration.preferenceOverrides[.automaticBackgroundUpdateCheck] = false

        // Ensure an update is available
        configuration.shellOutput[
            "curl -s --max-time 10 '\(Constants.Urls.DevBuildCaskFile.absoluteString)'"
        ] = .delayed(0.5, """
            cask 'phpmon-dev' do
                depends_on formula: 'gnu-sed'

                version '99.0.0_9999'
                sha256 '1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a'

                url 'https://github.com/nicoverbruggen/phpmon/releases/download/v99.0/phpmon-dev.zip'
                appcast 'https://github.com/nicoverbruggen/phpmon/releases.atom'
                name 'PHP Monitor DEV'
                homepage 'https://phpmon.app'

                app 'PHP Monitor DEV.app', target: "PHP Monitor DEV.app"
            end
            """)

        // Wait for the menu to open and search for updates
        let app = launch(openMenu: false, with: configuration)

        // The check should not happen if the preference is disabled
        assertNotExists(app.staticTexts["updater.alerts.newer_version_available.title".localized("99.0.0 (9999)")], 2)

        // Open the menu and check manually
        app.statusItems.firstMatch.click()
        app.menuItems["mi_check_for_updates".localized].click()

        // Expect to see the content of the appropriate alert box
        assertExists(app.staticTexts["updater.alerts.newer_version_available.title".localized("99.0.0 (9999)")], 2)
        assertExists(app.buttons["updater.alerts.buttons.install".localized])
        assertExists(app.buttons["updater.alerts.buttons.dismiss".localized])
    }

    final func test_could_not_parse_version() throws {
        var configuration = TestableConfigurations.working

        // Ensure automatic check is disabled
        configuration.preferenceOverrides[.automaticBackgroundUpdateCheck] = false

        // Ensure an update is available
        configuration.shellOutput[
            "curl -s --max-time 10 '\(Constants.Urls.DevBuildCaskFile.absoluteString)'"
        ] = .delayed(0.5, "404 PAGE NOT FOUND")

        // Wait for the menu to open and search for updates
        let app = launch(openMenu: true, with: configuration)
        app.menuItems["mi_check_for_updates".localized].click()

        // Expect to see the content of the appropriate alert box
        assertExists(app.staticTexts["updater.alerts.cannot_check_for_update.title".localized], 2)
        assertExists(app.buttons["generic.ok".localized])
        assertExists(app.buttons["updater.alerts.buttons.releases_on_github".localized])
    }
}
