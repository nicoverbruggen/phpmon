//
//  ServiceWrapper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 Whether a given service is active, inactive or PHP Monitor is still busy determining the status.
 */
public enum ServiceStatus: String {
    case active
    case inactive
    case missing
}

/**
 Service wrapper, that contains the Homebrew JSON output (if determined) and the formula.
 This helps the app determine whether a service should run as an administrator or not.
 */
public class ServiceWrapper: ObservableObject, Identifiable, Hashable {
    var formula: HomebrewFormula
    var service: HomebrewService?

    public var name: String {
        return formula.name
    }

    public var status: ServiceStatus {
        guard let service = self.service else {
            return .missing
        }

        return service.running ? .active : .inactive
    }

    init(formula: HomebrewFormula) {
        self.formula = formula
    }

    public static func == (lhs: ServiceWrapper, rhs: ServiceWrapper) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(formula)
        hasher.combine(service)
    }

    public func broadcastChanged() {
        Task { @MainActor in
            self.objectWillChange.send()
        }
    }
}
