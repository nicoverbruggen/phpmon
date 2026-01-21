//
//  UITestCase.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 15/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest

class UITestCase: XCTestCase {
    /** Launches the app and opens the menu. */
    public func launch(
        openMenu: Bool = false,
        with configuration: TestableConfiguration? = nil
    ) -> XCPMApplication {
        let app = XCPMApplication()
        let config = configuration ?? TestableConfigurations.working
        app.withConfiguration(config)
        app.launch()

        let statusItem = app.statusItems.firstMatch
        let isEnabled = NSPredicate(format: "isEnabled == true")
        let expectation = expectation(for: isEnabled, evaluatedWith: statusItem, handler: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: 15)

        if result == .timedOut {
            XCTFail("PHP Monitor did not initialize with an available UI element within 15 seconds.")
        }

        // Note: If this fails here, make sure the menu bar item can be displayed
        // If you use Bartender or something like this, this item may be hidden and tests will fail
        if openMenu {
            statusItem.click()
        }

        return app
    }

    /** Checks if a single element exists. */
    public func assertExists(_ element: XCUIElement, _ timeout: TimeInterval = 0.05) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
    }

    /** Checks if a single element fails to exist. */
    public func assertNotExists(_ element: XCUIElement, _ timeout: TimeInterval = 0.05) {
        XCTAssertFalse(element.waitForExistence(timeout: timeout))
    }

    /** Checks if all elements exist. */
    public func assertAllExist(_ elements: [XCUIElement], _ timeout: TimeInterval = 0.05) {
        for element in elements {
            XCTAssert(element.waitForExistence(timeout: timeout))
        }
    }

    /** Clicks on a given element. */
    public func click(_ element: XCUIElement) {
        element.click()
    }
}

extension XCPMApplication {
    /**
     Opens a given menu item found in the menu bar's status item.
     */
    public func mainMenuItem(withText text: String) -> XCUIElement {
        self.statusItems.firstMatch.menuItems[text].firstMatch
    }
}

extension XCUIElement {
    /**
     Clears all the text from a given element.
     */
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        var deleteString = String()
        for _ in stringValue {
            deleteString += XCUIKeyboardKey.delete.rawValue
        }
        typeText(deleteString)
    }
}
