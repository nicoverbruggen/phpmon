//
//  Errors.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

public protocol AlertableError {
    func getErrorMessageKey() -> String
}
