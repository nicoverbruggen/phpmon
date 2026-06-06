//
//  OnboardingActionDescriptor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct OnboardingActionDescriptor {
    let detailTitle: String
    let detailDescription: String
    let primaryButtonTitle: String
    let learnMoreLink: URL?
    let commandBlock: OnboardingViewState.CommandBlock?
    let usesStatusBanner: Bool
    let showsTerminalOutputWhenRunning: Bool

    init(
        detailTitle: String,
        detailDescription: String,
        primaryButtonTitle: String,
        learnMoreLink: URL? = nil,
        commandBlock: OnboardingViewState.CommandBlock? = nil,
        usesStatusBanner: Bool = false,
        showsTerminalOutputWhenRunning: Bool = false
    ) {
        self.detailTitle = detailTitle
        self.detailDescription = detailDescription
        self.primaryButtonTitle = primaryButtonTitle
        self.learnMoreLink = learnMoreLink
        self.commandBlock = commandBlock
        self.usesStatusBanner = usesStatusBanner
        self.showsTerminalOutputWhenRunning = showsTerminalOutputWhenRunning
    }
}

extension OnboardingActionDescriptor {
    static func startSetup() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.steps.introduction".localized,
            detailDescription: "onboarding_wizard.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.start_setup".localized
        )
    }

    static func installDeveloperTools() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.developer_tools.title".localized,
            detailDescription: "onboarding_wizard.detail.developer_tools.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.install_developer_tools".localized,
            learnMoreLink: Constants.Urls.AppleCommandLineTools
        )
    }

    static func recheckDeveloperTools() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.developer_tools.title".localized,
            detailDescription: "onboarding_wizard.detail.developer_tools.waiting".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.continue".localized,
            learnMoreLink: Constants.Urls.AppleCommandLineTools,
            usesStatusBanner: true
        )
    }

    static func installHomebrew() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.homebrew.title".localized,
            detailDescription: "onboarding_wizard.detail.homebrew.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.copy_command".localized,
            learnMoreLink: Constants.Urls.HomebrewWebsite,
            commandBlock: homebrewCommandBlock(),
            usesStatusBanner: true
        )
    }

    static func recheckHomebrew() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.homebrew.title".localized,
            detailDescription: "onboarding_wizard.detail.homebrew.waiting".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.check_again".localized,
            learnMoreLink: Constants.Urls.HomebrewWebsite,
            commandBlock: homebrewCommandBlock(),
            usesStatusBanner: true
        )
    }

    static func fixPathAutomatically() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.path.title".localized,
            detailDescription: "onboarding_wizard.detail.path.description.zsh".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.fix_path".localized
        )
    }

    static func recheckPath(
        configuredShellPath: String,
        instructionLines: [String]
    ) -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.path.title".localized,
            detailDescription: "onboarding_wizard.detail.path.description.manual".localized(
                configuredShellPath
            ),
            primaryButtonTitle: "onboarding_wizard.buttons.check_again".localized,
            commandBlock: OnboardingViewState.CommandBlock(
                title: "onboarding_wizard.command.path.title".localized,
                lines: instructionLines
            ),
            usesStatusBanner: true
        )
    }

    static func installPhpComposer() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.php_composer.title".localized,
            detailDescription: "onboarding_wizard.detail.php_composer.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.install_php_composer".localized,
            showsTerminalOutputWhenRunning: true
        )
    }

    static func installValet() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.valet.title".localized,
            detailDescription: "onboarding_wizard.detail.valet.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.install_valet".localized,
            showsTerminalOutputWhenRunning: true
        )
    }

    static func continueToStartup() -> Self {
        return Self(
            detailTitle: "onboarding_wizard.detail.ready.title".localized,
            detailDescription: "onboarding_wizard.detail.ready.description".localized,
            primaryButtonTitle: "onboarding_wizard.buttons.continue".localized
        )
    }

    private static func homebrewCommandBlock() -> OnboardingViewState.CommandBlock {
        return OnboardingViewState.CommandBlock(
            title: "onboarding_wizard.command.homebrew.title".localized,
            lines: [CommandCatalog.Onboarding.homebrewInstall]
        )
    }
}

struct IntroductionItemDescriptor {
    let step: OnboardingStep
    let title: String
    let description: String
}
