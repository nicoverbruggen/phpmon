//
//  Startup+OnboardingWizard.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Startup {
    enum OnboardingDisposition: Equatable {
        case wizard
        case normal
    }

    enum OnboardingWizardOutcome: Equatable {
        case completed
        case completedInStandaloneMode
        case quit
    }

    /**
     Determines whether the onboarding wizard should be shown for a genuinely fresh setup.

     The wizard is only intended for "new machine" scenarios:
     - Homebrew is missing entirely, or
     - Homebrew exists and none of the onboarding prerequisites are present yet.

     Any partial setup should fall through to the regular startup checks immediately.
     */
    func onboardingDisposition() async -> OnboardingDisposition {
        return await Self.onboardingDisposition(in: container)
    }

    func shouldShowOnboardingWizard() async -> Bool {
        return await Self.shouldShowOnboardingWizard(in: container)
    }

    @MainActor
    func showOnboardingWizard() async -> OnboardingWizardOutcome {
        return await OnboardingWizardWindowController.create().showModal()
    }

    static func onboardingDisposition(
        in container: Container
    ) async -> OnboardingDisposition {
        if !hasHomebrewInstalled(in: container) {
            return .wizard
        }

        if await hasAnyOnboardingPrerequisiteInstalled(in: container) {
            return .normal
        }

        return .wizard
    }

    static func shouldShowOnboardingWizard(in container: Container) async -> Bool {
        return await onboardingDisposition(in: container) == .wizard
    }

    static func hasHomebrewInstalled(in container: Container) -> Bool {
        return container.filesystem.fileExists(container.paths.brew)
    }

    static func hasAppleDeveloperToolsInstalled(in container: Container) async -> Bool {
        let output = await container.shell.pipe("/usr/bin/xcode-select -p")

        return !output.hasError
            && !output.out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func hasOnboardingPathConfigured(in container: Container) -> Bool {
        let pathEntries = pathEntries(in: container.shell.PATH, homePath: container.paths.homePath)

        return pathEntries.contains(normalizedPathEntry(container.paths.binPath, homePath: container.paths.homePath))
            && pathEntries.contains(normalizedPathEntry(
                "\(container.paths.homePath)/.composer/vendor/bin",
                homePath: container.paths.homePath
            ))
    }

    private static func hasAnyOnboardingPrerequisiteInstalled(in container: Container) async -> Bool {
        if await hasPhpInstalled(in: container) {
            return true
        }

        if hasComposerInstalled(in: container) {
            return true
        }

        if hasNginxInstalled(in: container) {
            return true
        }

        if hasDnsmasqInstalled(in: container) {
            return true
        }

        if hasValetInstalled(in: container) {
            return true
        }

        return false
    }

    static func hasPhpInstalled(in container: Container) async -> Bool {
        if container.filesystem.fileExists(container.paths.php) {
            return true
        }

        return await container.shell
            .pipe("ls \(container.paths.optPath) | grep php")
            .out
            .contains("php")
    }

    static func hasComposerInstalled(in container: Container) -> Bool {
        container.paths.detectBinaryPaths()
        return container.paths.composer != nil
    }

    private static func hasNginxInstalled(in container: Container) -> Bool {
        return container.filesystem.anyExists("\(container.paths.optPath)/nginx")
    }

    private static func hasDnsmasqInstalled(in container: Container) -> Bool {
        return container.filesystem.anyExists("\(container.paths.optPath)/dnsmasq")
    }

    private static func hasValetInstalled(in container: Container) -> Bool {
        return container.filesystem.fileExists(container.paths.valet)
            || container.filesystem.fileExists("~/.composer/vendor/bin/valet")
            || container.filesystem.directoryExists("~/.config/valet")
    }

    private static func pathEntries(in path: String, homePath: String) -> Set<String> {
        return Set(path
            .split(separator: ":")
            .map { normalizedPathEntry(String($0), homePath: homePath) }
        )
    }

    private static func normalizedPathEntry(_ path: String, homePath: String) -> String {
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
