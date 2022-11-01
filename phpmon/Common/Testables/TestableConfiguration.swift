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
        Log.separator()
        Log.info("USING TESTABLE CONFIGURATION...")
        Log.separator()
        Log.info("Applying fake shell...")
        ActiveShell.useTestable(shellOutput)
        Log.info("Applying fake filesystem...")
        ActiveFileSystem.useTestable(filesystem)
        Log.info("Applying fake commands...")
        ActiveCommand.useTestable(commandOutput)
        Log.info("Applying fake scanner...")
        ValetScanners.useFake()
        Log.separator()
    }

    func toJson(pretty: Bool = false) -> String {
        let data = try! JSONEncoder().encode(self)

        if pretty {
            return data.prettyPrintedJSONString! as String
        }

        return String(data: data, encoding: .utf8)!
    }

    static func loadFrom(path: String) -> TestableConfiguration {
        let url = URL(fileURLWithPath: path.replacingTildeWithHomeDirectory)

        return try! JSONDecoder().decode(
            TestableConfiguration.self,
            from: try! String(contentsOf: url, encoding: .utf8).data(using: .utf8)!
        )
    }
}
