//
//  NewShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class NewShell {
    static var shared: Shellable!

    public func useTestable(_ expectations: [String: String]) {
        Self.shared = TestableShell(expectations: expectations)
    }
}

protocol Shellable {
    func pipe(_ command: String) -> String
}

class SystemShell: Shellable {
    func pipe(_ command: String) -> String {
        return "shell output"
    }
}

class TestableShell: Shellable {
    init(expectations: [String: String]) {
        self.expectations = expectations
    }

    var expectations: [String: String] = [:]

    func pipe(_ command: String) -> String {
        return expectations[command] ?? ""
    }
}
