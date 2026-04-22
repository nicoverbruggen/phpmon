//
//  Startup+OnboardingWizard.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Startup {
    enum OnboardingWizardStartupDisposition: Equatable {
        case wizard
        case normal
    }

    /**
     Determines whether the onboarding wizard should be shown for a genuinely fresh setup.

     The wizard is only intended for "new machine" scenarios:
     - Homebrew is missing entirely, or
     - Homebrew exists and none of the onboarding prerequisites are present yet.

     Any partial setup should fall through to the regular startup checks immediately.
     */
    func onboardingWizardStartupDisposition() async -> OnboardingWizardStartupDisposition {
        return await Self.onboardingWizardStartupDisposition(in: container)
    }

    func shouldShowOnboardingWizard() async -> Bool {
        return await Self.shouldShowOnboardingWizard(in: container)
    }

    static func onboardingWizardStartupDisposition(
        in container: Container
    ) async -> OnboardingWizardStartupDisposition {
        if !hasHomebrewInstalled(in: container) {
            return .wizard
        }

        if await hasAnyOnboardingPrerequisiteInstalled(in: container) {
            return .normal
        }

        return .wizard
    }

    static func shouldShowOnboardingWizard(in container: Container) async -> Bool {
        return await onboardingWizardStartupDisposition(in: container) == .wizard
    }

    private static func hasHomebrewInstalled(in container: Container) -> Bool {
        return container.filesystem.fileExists(container.paths.brew)
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

    private static func hasPhpInstalled(in container: Container) async -> Bool {
        if container.filesystem.fileExists(container.paths.php) {
            return true
        }

        return await container.shell
            .pipe("ls \(container.paths.optPath) | grep php")
            .out
            .contains("php")
    }

    private static func hasComposerInstalled(in container: Container) -> Bool {
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
}
