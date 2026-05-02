//
//  Toolchain.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct Toolchain {
    let container: Container

    enum Tool: Equatable {
        case commandLineTools
        case homebrew
        case php
        case composer
        case nginx
        case dnsmasq
        case valet
    }

    struct Status: Equatable {
        let path: String?
        let installed: Bool
    }

    init(_ container: Container) {
        self.container = container
    }

    func status(_ tool: Tool) async -> Status {
        switch tool {
        case .commandLineTools:
            return await commandLineToolsStatus()
        case .homebrew:
            return Status(path: container.paths.brew, installed: container.filesystem.fileExists(container.paths.brew))
        case .php:
            return await phpStatus()
        case .composer:
            container.paths.detectBinaryPaths()
            return Status(
                path: container.paths.composer,
                installed: container.paths.composer != nil
            )
        case .nginx:
            let path = "\(container.paths.optPath)/nginx"
            return Status(path: path, installed: container.filesystem.anyExists(path))
        case .dnsmasq:
            let path = "\(container.paths.optPath)/dnsmasq"
            return Status(path: path, installed: container.filesystem.anyExists(path))
        case .valet:
            let primaryPath = container.paths.valet
            let composerPath = "\(container.paths.homePath)/.composer/vendor/bin/valet"
            let configPath = "~/.config/valet"

            if container.filesystem.fileExists(primaryPath) {
                return Status(path: primaryPath, installed: true)
            }

            if container.filesystem.directoryExists(configPath) {
                return Status(path: configPath, installed: true)
            }

            return Status(
                path: composerPath,
                installed: container.filesystem.fileExists("~/.composer/vendor/bin/valet")
            )
        }
    }

    func onboardingDisposition() async -> Startup.OnboardingDisposition {
        let developerToolsInstalled = await status(.commandLineTools).installed
        let homebrewInstalled = await status(.homebrew).installed
        let phpInstalled = await status(.php).installed
        let composerInstalled = await status(.composer).installed

        if !homebrewInstalled {
            return .wizard
        }

        if Stats.successfulLaunchCount > 0 {
            return .normal
        }

        if developerToolsInstalled && phpInstalled && composerInstalled {
            return .normal
        }

        return .wizard
    }

    private func commandLineToolsStatus() async -> Status {
        let output = await container.shell.pipe(Commands.commandLineToolsStatus)
        let path = output.out.trimmingCharacters(in: .whitespacesAndNewlines)

        return Status(
            path: path.isEmpty ? nil : path,
            installed: !output.hasError && !path.isEmpty
        )
    }

    private func phpStatus() async -> Status {
        if container.filesystem.fileExists(container.paths.php) {
            return Status(path: container.paths.php, installed: true)
        }

        let formulaeOutput = await container.shell.pipe("ls \(container.paths.optPath) | grep php")
        let installed = formulaeOutput.out.contains("php")

        return Status(
            path: installed ? "\(container.paths.optPath)/php" : nil,
            installed: installed
        )
    }
}
