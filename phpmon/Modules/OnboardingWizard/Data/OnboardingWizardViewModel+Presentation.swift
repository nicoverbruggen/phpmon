//
//  OnboardingWizardViewModel+Presentation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension OnboardingWizardViewModel {
    var detailTitle: String {
        switch action {
        case .installDeveloperTools, .recheckDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.title".localized
        case .installHomebrew:
            return "onboarding_wizard.detail.homebrew.title".localized
        case .fixPathAutomatically, .recheckPath:
            return "onboarding_wizard.detail.path.title".localized
        case .installPhpComposer:
            return "onboarding_wizard.detail.php_composer.title".localized
        case .continueToStartup:
            return "onboarding_wizard.detail.ready.title".localized
        }
    }

    var detailDescription: String {
        switch action {
        case .installDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.description".localized
        case .recheckDeveloperTools:
            return "onboarding_wizard.detail.developer_tools.waiting".localized
        case .installHomebrew:
            return "onboarding_wizard.detail.homebrew.description".localized
        case .fixPathAutomatically:
            return "onboarding_wizard.detail.path.description.zsh".localized
        case .recheckPath:
            return "onboarding_wizard.detail.path.description.manual".localized(container.paths.configuredShellPath)
        case .installPhpComposer:
            return "onboarding_wizard.detail.php_composer.description".localized
        case .continueToStartup:
            return "onboarding_wizard.detail.ready.description".localized
        }
    }

    var commandTitle: String? {
        switch action {
        case .recheckPath:
            return "onboarding_wizard.command.path.title".localized
        case .installPhpComposer:
            return "onboarding_wizard.command.php_composer.title".localized
        default:
            return nil
        }
    }

    var commandLines: [String] {
        switch action {
        case .recheckPath:
            return ShellEnvironment(container).pathInstructionLines()
        case .installPhpComposer:
            return [Toolchain.Commands.phpComposerInstall]
        default:
            return []
        }
    }

    var primaryButtonTitle: String {
        switch action {
        case .installDeveloperTools:
            return "onboarding_wizard.buttons.install_developer_tools".localized
        case .recheckDeveloperTools:
            return "onboarding_wizard.buttons.continue".localized
        case .recheckPath:
            return "onboarding_wizard.buttons.check_again".localized
        case .installHomebrew:
            return "onboarding_wizard.buttons.install_homebrew".localized
        case .fixPathAutomatically:
            return "onboarding_wizard.buttons.fix_path".localized
        case .installPhpComposer:
            return "onboarding_wizard.buttons.install_php_composer".localized
        case .continueToStartup:
            return "onboarding_wizard.buttons.continue".localized
        }
    }
}
