//
//  HomebrewPermissionError.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewPermissionError: Error, AlertableError {
    enum Kind: String {
        case applescriptNilError = "homebrew_permissions.applescript_returned_nil"
    }
    
    let kind: Kind
    
    func getErrorMessageKey() -> String {
        return "alert.errors.\(self.kind.rawValue)"
    }
}
