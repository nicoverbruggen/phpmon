//
//  EnvironmentCheck.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 The `EnvironmentCheck` is used to defer the execution of all of these commands until necessary.
 Checks that require an app restart will always lead to an alert and app termination shortly after.
 */
struct EnvironmentCheck {
    let command: () async -> Bool
    let name: String
    let titleText: String
    let subtitleText: String
    let descriptionText: String
    let buttonText: String
    let requiresAppRestart: Bool

    init(
        command: @escaping () async -> Bool,
        name: String,
        titleText: String,
        subtitleText: String,
        descriptionText: String = "",
        buttonText: String = "OK",
        requiresAppRestart: Bool = false
    ) {
        self.command = command
        self.name = name
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.descriptionText = descriptionText
        self.buttonText = buttonText
        self.requiresAppRestart = requiresAppRestart
    }

    public func succeeds() async -> Bool {
        return await !self.command()
    }
}
