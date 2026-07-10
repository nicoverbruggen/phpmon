//
//  SettingsCaptureTest.swift
//  UI Tests
//
//  Capture harness for the storyboard → SwiftUI migration: captures a
//  screenshot of every Settings tab so before/after implementations can be
//  compared for content parity. Only runs when TEST_RUNNER_PHPMON_CAPTURE_DIR
//  is passed to xcodebuild; skipped otherwise (CI and normal runs unaffected).
//  Extract the shots from the result bundle: xcrun xcresulttool export attachments.
//
//  Delete this file once the storyboard migration is fully complete.
//

import XCTest

final class SettingsCaptureTest: UITestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["PHPMON_CAPTURE_DIR"] == nil,
            "Capture harness only runs when PHPMON_CAPTURE_DIR is set."
        )
    }

    final func test_capture_progress_panel() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")
        // Keep the panel open long enough to capture it, with some console output.
        configuration.shellOutput["/usr/local/bin/composer global update"] = .delayed(
            8.0,
            "Updating dependencies...\nNothing to install, update or remove\n"
        )

        let app = launch(openMenu: true, with: configuration)

        app.mainMenuItem(withText: "mi_update_global_composer".localized(for: "en")).click()

        let title = app.staticTexts["alert.composer_progress.title".localized(for: "en")]
        assertExists(title, 5.0)

        // Give the console a moment to render the command line
        Thread.sleep(forTimeInterval: 1.5)

        let panel = app.windows
            .containing(.staticText, identifier: "alert.composer_progress.title".localized(for: "en"))
            .firstMatch
        assertExists(panel, 2.0)

        let attachment = XCTAttachment(screenshot: panel.screenshot())
        attachment.name = "progress-panel"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    final func test_capture_settings_tabs() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")

        let app = launch(openMenu: true, with: configuration)

        app.mainMenuItem(withText: "mi_preferences".localized(for: "en")).click()

        let window = app.windows
            .containing(.button, identifier: "prefs.tabs.general".localized(for: "en"))
            .firstMatch
        assertExists(window, 2.0)

        for tab in ["general", "appearance", "visibility", "notifications"] {
            let button = app.buttons["prefs.tabs.\(tab)".localized(for: "en")]
            assertExists(button, 2.0)
            button.click()

            // Give the tab switch animation a moment to settle
            Thread.sleep(forTimeInterval: 0.75)

            // Attachments land in the result bundle (the runner is sandboxed
            // and cannot write to arbitrary paths); extract them afterwards
            // with `xcrun xcresulttool`.
            let attachment = XCTAttachment(screenshot: window.screenshot())
            attachment.name = "settings-\(tab)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
