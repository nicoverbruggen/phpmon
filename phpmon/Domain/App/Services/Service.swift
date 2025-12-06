//
//  ServiceWrapper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/** Service linked to a Homebrew formula and whether it is currently (in)active or missing. */
public struct Service: Hashable {
    var formula: HomebrewFormula
    var status: Status = .missing

    public var name: String {
        return formula.name
    }

    init(formula: HomebrewFormula, service: HomebrewService? = nil) {
        self.formula = formula

        guard let service else { return }

        self.status = service.running ? .active : .inactive

        if service.status == "error" {
            self.status = .error
        }
    }

    // MARK: - Protocols

    public static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(formula)
        hasher.combine(status)
    }

    // MARK: - Status

    public enum Status: String {
        case active
        case inactive
        case error
        case missing

        var asBool: Bool {
            return self == .active
        }
    }
}
