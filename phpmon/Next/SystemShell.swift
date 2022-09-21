//
//  SystemShell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class SystemShell: Shellable {
    public var launchPath: String = "/bin/sh"

    public var PATH: String = {
        let task = Process()
        task.launchPath = "/bin/zsh"

        // We need an interactive shell so the user's PATH is loaded in correctly
        task.arguments = ["--login", "-ilc", "echo $PATH"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        return String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: String.Encoding.utf8
        ) ?? ""
    }()

    var exports: String = ""

    private func getShellProcess(for command: String) -> Process {
        var completeCommand = ""

        // Basic export (PATH)
        completeCommand += "export PATH=\(Paths.binPath):$PATH && "

        // Put additional exports (as defined by the user) in between
        if !self.exports.isEmpty {
            completeCommand += "\(self.exports) && "
        }

        completeCommand += command

        let task = Process()
        task.launchPath = self.launchPath
        task.arguments = ["--noprofile", "-norc", "--login", "-c", completeCommand]
        return task
    }

    // MARK: - Shellable Protocol

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
