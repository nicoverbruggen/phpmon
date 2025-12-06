//
//  VersionParseError.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// MARK: - Alertable Errors
// These errors must be resolved by the user.

struct HomebrewPermissionError: Error, AlertableError {
    enum Kind: String {
        case applescriptNilError = "homebrew_permissions.applescript_returned_nil"
    }

    let kind: Kind

    func getErrorMessageKey() -> String {
        return "alert.errors.\(self.kind.rawValue)"
    }
}

// MARK: - Errors that do not have an associated alert message
// The errors must be resolved by the developer.

struct VersionParseError: Error {}
