//
//  TestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableShell: Shellable {
    init(expectations: [String: String]) {
        self.expectations = expectations
    }

    var expectations: [String: String] = [:]

    func pipe(_ command: String) async -> String {
        return expectations[command] ?? ""
    }

    func syncPipe(_ command: String) -> String {
        return expectations[command] ?? ""
    }
    }
