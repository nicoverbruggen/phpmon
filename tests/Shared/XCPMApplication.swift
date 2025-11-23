//
//  XCPMApplication.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import XCTest

class XCPMApplication: XCUIApplication {
    public func withConfiguration(_ configuration: TestableConfiguration) {
        let path = persistTestable(configuration)
        self.launchArguments = ["--configuration:\(path)"]
    }

    private func persistTestable(_ configuration: TestableConfiguration) -> String {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent("\(UUID().uuidString).json")
        try! configuration.toJson().write(toFile: targetURL.path, atomically: true, encoding: .utf8)
        return targetURL.path
    }
}
