//
//  Shell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

var Shell: Shellable {
    return ActiveShell.shared
}

class ActiveShell {
    static var shared: Shellable = SystemShell()

    /// Uses a testable shell with predefined responses. You specify the terminal's output.
    /// they also work with simple String objects.
    public static func useTestable(_ expectations: [String: OutputsToShell]) {
        Self.shared = TestableShell(expectations: expectations)
    }

    /// Reverts back to the system shell. You do not need to call this, only after using `useTestable()`.
    public static func useSystem() {
        Self.shared = SystemShell()
    }
}
