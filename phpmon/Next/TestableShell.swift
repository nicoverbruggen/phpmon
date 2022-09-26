//
//  TestableShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public class TestableShell: Shellable {

    public typealias Input = String

    init(expectations: [Input: OutputsToShell]) {
        self.expectations = expectations
    }

    var expectations: [Input: OutputsToShell] = [:]

    func pipe(_ command: String) async -> String {
        // TODO: Deal with the duration and output to error
        return expectations[command]?.getOutputAsString() ?? ""
    }

    func syncPipe(_ command: String) -> String {
        // TODO: Deal with the duration and output to error
        return expectations[command]?.getOutputAsString() ?? ""
    }
}

protocol OutputsToShell {
    func getOutputAsString() -> String
    func getDuration() -> Int
    func outputsToError() -> Bool
}

struct FakeTerminalOutput: OutputsToShell {
    var output: String
    var duration: Int
    var isError: Bool

    func getOutputAsString() -> String {
        return output
    }

    func getDuration() -> Int {
        return duration
    }

    func outputsToError() -> Bool {
        return isError
    }
}

extension String: OutputsToShell {
    func getOutputAsString() -> String {
        return self
    }

    func getDuration() -> Int {
        return 100
    }

    func outputsToError() -> Bool {
        return false
    }
}
