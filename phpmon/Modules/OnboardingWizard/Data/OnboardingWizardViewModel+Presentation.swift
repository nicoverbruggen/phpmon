//
//  OnboardingWizardViewModel+Presentation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension OnboardingWizardViewModel {
    var usesStatusBanner: Bool {
        switch action {
        case .recheckDeveloperTools, .installHomebrew, .recheckHomebrew, .recheckPath:
            return true
        case .startSetup, .installDeveloperTools, .fixPathAutomatically, .installPhpComposer,
            .installValet, .continueToStartup:
            return false
        }
    }

    var latestOutputText: String? {
        return outputLines
            .map(\.text)
            .reversed()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    var showsStatusBanner: Bool {
        usesStatusBanner && latestOutputText != nil
    }

    var statusBannerText: String? {
        guard usesStatusBanner else {
            return nil
        }

        return latestOutputText
    }

    var statusBannerIsFailure: Bool {
        return outputLines.last?.stream == .stdErr
    }

    var showsTerminalOutput: Bool {
        return shouldShowTerminalOutput && showsOutput && !usesStatusBanner
    }

    var learnMoreLink: URL? {
        switch action {
        case .startSetup:
            return nil
        case .installDeveloperTools, .recheckDeveloperTools:
            return Constants.Urls.AppleCommandLineTools
        case .installHomebrew, .recheckHomebrew:
            return Constants.Urls.HomebrewWebsite
        default:
            return nil
        }
    }

    var detailTitle: String {
        switch action {
        case .startSetup:
            return "onboarding_wizard.steps.introduction".localized
        case .installDeveloperTools, .recheckDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.title".localized
        case .installHomebrew, .recheckHomebrew:
            return "onboarding_wizard.detail.homebrew.title".localized
        case .fixPathAutomatically, .recheckPath:
            return "onboarding_wizard.detail.path.title".localized
        case .installPhpComposer:
            return "onboarding_wizard.detail.php_composer.title".localized
        case .installValet:
            return "onboarding_wizard.detail.valet.title".localized
        case .continueToStartup:
            return "onboarding_wizard.detail.ready.title".localized
        }
    }

    var detailDescription: String {
        switch action {
        case .startSetup:
            return "onboarding_wizard.description".localized
        case .installDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.description".localized
        case .recheckDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.waiting".localized
        case .installHomebrew:
            return "onboarding_wizard.detail.homebrew.description".localized
        case .recheckHomebrew:
            return "onboarding_wizard.detail.homebrew.waiting".localized
        case .fixPathAutomatically:
            return "onboarding_wizard.detail.path.description.zsh".localized
        case .recheckPath:
            return "onboarding_wizard.detail.path.description.manual".localized(container.paths.configuredShellPath)
        case .installPhpComposer:
            return "onboarding_wizard.detail.php_composer.description".localized
        case .installValet:
            return "onboarding_wizard.detail.valet.description".localized
        case .continueToStartup:
            return "onboarding_wizard.detail.ready.description".localized
        }
    }

    var commandTitle: String? {
        switch action {
        case .startSetup:
            return nil
        case .installHomebrew, .recheckHomebrew:
            return "onboarding_wizard.command.homebrew.title".localized
        case .recheckPath:
            return "onboarding_wizard.command.path.title".localized
        default:
            return nil
        }
    }

    var commandLines: [String] {
        switch action {
        case .startSetup:
            return []
        case .installHomebrew, .recheckHomebrew:
            return [Toolchain.Commands.homebrewInstall]
        case .recheckPath:
            return ShellEnvironment(container).pathInstructionLines()
        default:
            return []
        }
    }

    var primaryButtonTitle: String {
        switch action {
        case .startSetup:
            return "onboarding_wizard.buttons.start_setup".localized
        case .installDeveloperTools:
            return "onboarding_wizard.buttons.install_developer_tools".localized
        case .recheckDeveloperTools:
            return "onboarding_wizard.buttons.continue".localized
        case .installHomebrew:
            return "onboarding_wizard.buttons.copy_command".localized
        case .recheckHomebrew, .recheckPath:
            return "onboarding_wizard.buttons.check_again".localized
        case .fixPathAutomatically:
            return "onboarding_wizard.buttons.fix_path".localized
        case .installPhpComposer:
            return "onboarding_wizard.buttons.install_php_composer".localized
        case .installValet:
            return "onboarding_wizard.buttons.install_valet".localized
        case .continueToStartup:
            return "onboarding_wizard.buttons.continue".localized
        }
    }
}
