//
//  UITestCase.swift
//  UI Tests
//
//  Created by Nico Verbruggen on 15/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class UITestCase: XCTestCase {

    /** Checks if a single element exists. */
    public func assertExists(_ element: XCUIElement, _ timeout: TimeInterval = 0.05) {
        XCTAssert(element.waitForExistence(timeout: timeout))
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
