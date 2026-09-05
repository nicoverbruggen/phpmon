//
//  ComposerProgressTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import XCTest

/**
 Tests the terminal progress panel via the global Composer update flow — the
 panel's only consumer. The fake shell streams delayed output, so the panel's
 full lifecycle can be observed: appear, stream console output, auto-close.
 */
final class ComposerProgressTest: UITestCase {

    final func test_composer_update_shows_progress_panel_and_closes_on_success() throws {
        var configuration = TestableConfigurations.working
        configuration.preferenceOverrides[.languageOverride] = .string("en")
        // Two chunks: the first streams early (proving live output), the second
        // ends the command a few seconds later (letting the panel auto-close).
        configuration.shellOutput["/usr/local/bin/composer global update"] = .with([
            .delayed(1.0, "Updating dependencies...\n"),
            .delayed(4.0, "Nothing to install, update or remove\n")
        ])

        let app = launch(openMenu: true, with: configuration)

        app.menuItems["mi_update_global_composer".localized(for: "en")].click()

        // The panel appears with its title and description
        let title = app.staticTexts["alert.composer_progress.title".localized(for: "en")]
        assertExists(title, 10.0)
        assertExists(app.staticTexts["alert.composer_progress.info".localized(for: "en")], 5.0)

        // The console streams the command itself, then its (delayed) output
        let console = app.textViews["ProgressPanelConsole"]
        assertExists(console, 5.0)

        XCTAssertTrue(
            waitForConsole(console, toContain: "composer global update"),
            "The console should show the command that is being executed."
        )
        XCTAssertTrue(
            waitForConsole(console, toContain: "Updating dependencies"),
            "The console should stream the command's (delayed) output."
        )

        // On success, the panel closes by itself shortly afterwards
        // (the final output chunk is not asserted: it only appears for the
        // last second before the panel closes, which races the slow
        // accessibility snapshotting).
        var panelClosed = false
        for _ in 0..<40 where !panelClosed {
            if !title.exists {
                panelClosed = true
                break
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        XCTAssertTrue(panelClosed, "The panel should close automatically after a successful update.")
    }

    /** Polls the console's accessibility value until it contains the given text. */
    private func waitForConsole(
        _ console: XCUIElement,
        toContain text: String,
        timeout: TimeInterval = 5.0
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let value = console.value as? String, value.contains(text) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.25)
        }

        return false
    }
}
