//
//  BrewCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol BrewCommand {
    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws
}

extension BrewCommand {
    internal func reportInstallationProgress(_ text: String) -> (Double, String)? {
        if text.contains("Fetching") {
            return (0.1, "phpman.steps.fetching".localized)
        }
        if text.contains("Downloading") {
            return (0.25, "phpman.steps.downloading".localized)
        }
        if text.contains("Installing") {
            return (0.60, "phpman.steps.installing".localized)
        }
        if text.contains("Pouring") {
            return (0.80, "phpman.steps.pouring".localized)
        }
        if text.contains("Summary") {
            return (0.90, "phpman.steps.summary".localized)
        }
        return nil
    }
}

struct BrewCommandProgress {
    let value: Double
    let title: String
    let description: String

    public static func create(value: Double, title: String, description: String) -> BrewCommandProgress {
        return BrewCommandProgress(value: value, title: title, description: description)
    }
}

struct BrewCommandError: Error {
    let error: String
}
