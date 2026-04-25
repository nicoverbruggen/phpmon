//
//  ShellEnvironment.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct ShellEnvironment {
    let container: Container

    struct PathEntryStatus: Equatable {
        let path: String
        let configured: Bool
    }

    init(_ container: Container) {
        self.container = container
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
            pathEntryStatus(for: "\(container.paths.homePath)/.composer/vendor/bin")
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
            .map { normalizePathEntry(String($0), homePath: container.paths.homePath) }
        )
    }

    private func pathEntryStatus(for path: String) -> PathEntryStatus {
        return PathEntryStatus(
            path: path,
            configured: pathEntries().contains(
                normalizePathEntry(path, homePath: container.paths.homePath)
            )
        )
    }

    private static func normalizePathEntry(_ path: String, homePath: String) -> String {
        var normalized = path

        if normalized == "~" || normalized == "$HOME" {
            normalized = homePath
        } else if normalized.hasPrefix("~/") {
            normalized = homePath + String(normalized.dropFirst(1))
        } else if normalized.hasPrefix("$HOME/") {
            normalized = homePath + String(normalized.dropFirst("$HOME".count))
        }

        while normalized.count > 1 && normalized.hasSuffix("/") {
            normalized.removeLast()
        }

        return normalized
    }
}
