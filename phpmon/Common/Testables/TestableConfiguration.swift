//
//  TestableConfiguration.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public struct TestableConfiguration: Codable {
    var architecture: String
    var filesystem: [String: FakeFile]
    var shellOutput: [String: BatchFakeShellOutput]
    var commandOutput: [String: String]

    func apply() {
        ActiveShell.useTestable(shellOutput)
        ActiveFileSystem.useTestable(filesystem)
        ActiveCommand.useTestable(commandOutput)
    }

    func toJson(pretty: Bool = false) -> String {
        let data = try! JSONEncoder().encode(self)

        if pretty {
            return data.prettyPrintedJSONString! as String
        }

        return String(data: data, encoding: .utf8)!
    }

    static func loadFrom(path: String) -> TestableConfiguration {
        return try! JSONDecoder().decode(
            TestableConfiguration.self,
            from: try! String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
                .data(using: .utf8)!
        )
    }
}