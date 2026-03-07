//
//  Container+Real.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

extension Container {
    public static func real(minimal: Bool = false, commandTracking: Bool = true) -> Container {
        let container = Container()
        container.bind(coreOnly: minimal, commandTracking: commandTracking)
        return container
    }
}
