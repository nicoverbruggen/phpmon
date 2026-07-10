//
//  Errors.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

public protocol AlertableError {
    // `nonisolated`: alertable errors are thrown/inspected across isolation
    // boundaries (e.g. off-main error handling), so the requirement must not be
    // main-actor isolated. Conformers like `AdminPrivilegeError` are `nonisolated`.
    nonisolated func getErrorMessageKey() -> String
}
