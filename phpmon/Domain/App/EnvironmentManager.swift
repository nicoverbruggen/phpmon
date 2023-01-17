//
//  EnvironmentManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public class EnvironmentManager {
    static var values: [EnvironmentProperty: Bool] = [:]

    public func process() async {
        Self.values[.hasValetInstalled] = Valet.shared.installed
    }
}

public enum EnvironmentProperty {
    case hasHomebrewInstalled
    case hasValetInstalled
}
