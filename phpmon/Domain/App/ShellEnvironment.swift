//
//  ShellEnvironment.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ShellEnvironment {
    let container: Container

    struct PathEntryStatus: Equatable {
        let path: String
        let configured: Bool
    }

    init(_ container: Container) {
        self.container = container
    }

    static func configuredShell() -> String {
        return system("dscl . -read ~/ UserShell | sed 's/UserShell: //'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validatedShellPath(_ path: String) -> String {
        if isAccessibleExecutable(path) {
            return path
        }

        return "/bin/zsh"
    }

    var configuredShell: String {
        return container.paths.configuredShellPath
    }

    var resolvedShell: String {
        return container.paths.shell
    }

    var isConfiguredShellValid: Bool {
        return container.paths.isConfiguredShellValid
    }

    func onboardingPathStatus() -> [PathEntryStatus] {
        return [
            pathEntryStatus(for: container.paths.binPath),
            pathEntryStatus(for: "\(container.paths.homePath)/.composer/vendor/bin"),
            pathEntryStatus(for: "\(container.paths.homePath)/.config/phpmon/bin")
        ]
    }

    func hasRequiredOnboardingPaths() -> Bool {
        return onboardingPathStatus().allSatisfy(\.configured)
    }

    var homebrewBinPathExport: String {
        return "export PATH=$HOME/bin:\(container.paths.binPath):$PATH"
    }

    var composerBinPathExport: String {
        return "export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH"
    }

    var phpMonitorBinPathExport: String {
        return "export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH"
    }

    private func pathEntries() -> Set<String> {
        return Set(container.shell.PATH
            .split(separator: ":")
            .map { PathEntry.normalize(String($0), homePath: container.paths.homePath) }
        )
    }

    private func pathEntryStatus(for path: String) -> PathEntryStatus {
        return PathEntryStatus(
            path: path,
            configured: pathEntries().contains(
                PathEntry.normalize(path, homePath: container.paths.homePath)
            )
        )
    }

    private static func isAccessibleExecutable(_ path: String) -> Bool {
        guard !path.isEmpty else {
            return false
        }

        let fileManager = FileManager.default

        return fileManager.isExecutableFile(atPath: path)
            && fileManager.isReadableFile(atPath: path)
    }
}
