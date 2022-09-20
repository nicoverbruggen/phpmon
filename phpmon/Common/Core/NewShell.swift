//
//  NewShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class NewShell {
    static var shared: Shellable = SystemShell()

    /// Uses a testable shell with predefined responses. You specify the terminal's output.
    public static func useTestable(_ expectations: [String: String]) {
        Self.shared = TestableShell(expectations: expectations)
    }

    /// Reverts back to the system shell. You do not need to call this, only after using `useTestable()`.
    public static func useSystem() {
        Self.shared = SystemShell()
    }
}

protocol Shellable {
    func syncPipe(_ command: String) -> String
    func pipe(_ command: String) async -> String
}

class SystemShell: Shellable {
    public var launchPath: String = "/bin/sh"

    public var exports: String = ""

    private func getShellProcess(for command: String) -> Process {
        var completeCommand = ""

        // Basic export (PATH)
        completeCommand += "export PATH=\(Paths.binPath):$PATH && "

        // Put additional exports in between
        if !self.exports.isEmpty {
            completeCommand += "\(self.exports) && "
        }

        completeCommand += command

        let task = Process()
        task.launchPath = self.launchPath
        task.arguments = ["--noprofile", "-norc", "--login", "-c", completeCommand]
        return task
    }

    func syncPipe(_ command: String) -> String {
        let task = getShellProcess(for: command)
        let pipe = Pipe()

        task.standardOutput = pipe
        task.launch()

        return String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }

    func pipe(_ command: String) async -> String {
        // TODO
        return ""
    }
}

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
