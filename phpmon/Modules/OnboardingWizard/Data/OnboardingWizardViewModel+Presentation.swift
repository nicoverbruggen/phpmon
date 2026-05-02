//
//  OnboardingWizardViewModel+Presentation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

enum StepStatus: Equatable {
    case pending
    case active
    case running
    case failed
    case completed

    var isActive: Bool {
        switch self {
        case .active, .running, .failed:
            return true
        case .pending, .completed:
            return false
        }
    }
}

struct OnboardingViewState {
    enum FocusTarget: Equatable {
        case primary
    }

    struct SidebarItem: Identifiable, Equatable {
        let step: OnboardingStep
        let status: StepStatus
        let title: String
        let badgeTitle: String?
        let isFirst: Bool
        let isLast: Bool

        var id: OnboardingStep {
            step
        }
    }

    struct IntroductionItem: Identifiable, Equatable {
        let step: OnboardingStep
        let number: Int
        let title: String
        let badgeTitle: String?
        let description: String
        let isCompleted: Bool

        var id: OnboardingStep {
            step
        }
    }

    struct CommandBlock: Equatable {
        let title: String
        let lines: [String]
    }

    struct StatusBanner: Equatable {
        let text: String
        let isFailure: Bool
    }

    let isShowingIntroduction: Bool
    let sidebarItems: [SidebarItem]
    let introductionItems: [IntroductionItem]
    let introductionFooterText: String
    let currentProgressText: String
    let activeStepNumber: Int?
    let detailTitle: String
    let detailDescription: String
    let primaryButtonTitle: String
    let primaryButtonDisabled: Bool
    let commandBlock: CommandBlock?
    let statusBanner: StatusBanner?
    let showsTerminalOutput: Bool
    let outputLines: [OutputLine]
    let isRunning: Bool
    let showsSkipValetButton: Bool
    let learnMoreLink: URL?
    let focusTarget: FocusTarget?
}

private struct OnboardingActionDescriptor {
    let detailTitle: String
    let detailDescription: String
    let primaryButtonTitle: String
    let learnMoreLink: URL?
    let commandBlock: OnboardingViewState.CommandBlock?
    let usesStatusBanner: Bool
    let showsTerminalOutputWhenRunning: Bool
}

extension OnboardingWizardViewModel {
    var primaryButtonDisabled: Bool {
        return viewState.primaryButtonDisabled
    }

    var learnMoreLink: URL? {
        return viewState.learnMoreLink
    }

    var commandTitle: String? {
        return viewState.commandBlock?.title
    }

    var commandLines: [String] {
        return viewState.commandBlock?.lines ?? []
    }

    var primaryButtonTitle: String {
        return viewState.primaryButtonTitle
    }

    var showsStatusBanner: Bool {
        return viewState.statusBanner != nil
    }

    var statusBannerText: String? {
        return viewState.statusBanner?.text
    }

    var statusBannerIsFailure: Bool {
        return viewState.statusBanner?.isFailure ?? false
    }

    var showsTerminalOutput: Bool {
        return viewState.showsTerminalOutput
    }

    var viewState: OnboardingViewState {
        let descriptor = descriptor(for: action)
        let activeStepNumber = activeStepNumber(for: currentStep)
        let latestOutputText = outputLines
            .map(\.text)
            .reversed()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        let statusBanner = descriptor.usesStatusBanner && latestOutputText != nil
            ? OnboardingViewState.StatusBanner(
                text: latestOutputText ?? "",
                isFailure: outputLines.last?.stream == .stdErr
            )
            : nil

        return OnboardingViewState(
            isShowingIntroduction: currentStep == .introduction,
            sidebarItems: makeSidebarItems(),
            introductionItems: makeIntroductionItems(),
            introductionFooterText: "onboarding_wizard.intro.footer".localized,
            currentProgressText: progressText(for: activeStepNumber),
            activeStepNumber: activeStepNumber,
            detailTitle: descriptor.detailTitle,
            detailDescription: descriptor.detailDescription,
            primaryButtonTitle: descriptor.primaryButtonTitle,
            primaryButtonDisabled: !hasLoaded || state == .running,
            commandBlock: descriptor.commandBlock,
            statusBanner: statusBanner,
            showsTerminalOutput: descriptor.showsTerminalOutputWhenRunning
                && state == .running
                && !outputLines.isEmpty
                && statusBanner == nil,
            outputLines: outputLines,
            isRunning: state == .running,
            showsSkipValetButton: currentStep == .valet,
            learnMoreLink: descriptor.learnMoreLink,
            focusTarget: !hasLoaded || state == .running ? nil : .primary
        )
    }

    private func descriptor(for action: OnboardingAction) -> OnboardingActionDescriptor {
        switch action {
        case .startSetup:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.steps.introduction".localized,
                detailDescription: "onboarding_wizard.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.start_setup".localized,
                learnMoreLink: nil,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: false
            )
        case .installDeveloperTools:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.developer_tools.title".localized,
                detailDescription: "onboarding_wizard.detail.developer_tools.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.install_developer_tools".localized,
                learnMoreLink: Constants.Urls.AppleCommandLineTools,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: false
            )
        case .recheckDeveloperTools:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.developer_tools.title".localized,
                detailDescription: "onboarding_wizard.detail.developer_tools.waiting".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.continue".localized,
                learnMoreLink: Constants.Urls.AppleCommandLineTools,
                commandBlock: nil,
                usesStatusBanner: true,
                showsTerminalOutputWhenRunning: false
            )
        case .installHomebrew:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.homebrew.title".localized,
                detailDescription: "onboarding_wizard.detail.homebrew.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.copy_command".localized,
                learnMoreLink: Constants.Urls.HomebrewWebsite,
                commandBlock: OnboardingViewState.CommandBlock(
                    title: "onboarding_wizard.command.homebrew.title".localized,
                    lines: [CommandCatalog.Onboarding.homebrewInstall]
                ),
                usesStatusBanner: true,
                showsTerminalOutputWhenRunning: false
            )
        case .recheckHomebrew:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.homebrew.title".localized,
                detailDescription: "onboarding_wizard.detail.homebrew.waiting".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.check_again".localized,
                learnMoreLink: Constants.Urls.HomebrewWebsite,
                commandBlock: OnboardingViewState.CommandBlock(
                    title: "onboarding_wizard.command.homebrew.title".localized,
                    lines: [CommandCatalog.Onboarding.homebrewInstall]
                ),
                usesStatusBanner: true,
                showsTerminalOutputWhenRunning: false
            )
        case .fixPathAutomatically:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.path.title".localized,
                detailDescription: "onboarding_wizard.detail.path.description.zsh".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.fix_path".localized,
                learnMoreLink: nil,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: false
            )
        case .recheckPath:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.path.title".localized,
                detailDescription: "onboarding_wizard.detail.path.description.manual".localized(
                    container.paths.configuredShellPath
                ),
                primaryButtonTitle: "onboarding_wizard.buttons.check_again".localized,
                learnMoreLink: nil,
                commandBlock: OnboardingViewState.CommandBlock(
                    title: "onboarding_wizard.command.path.title".localized,
                    lines: ShellEnvironment(container).pathInstructionLines()
                ),
                usesStatusBanner: true,
                showsTerminalOutputWhenRunning: false
            )
        case .installPhpComposer:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.php_composer.title".localized,
                detailDescription: "onboarding_wizard.detail.php_composer.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.install_php_composer".localized,
                learnMoreLink: nil,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: true
            )
        case .installValet:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.valet.title".localized,
                detailDescription: "onboarding_wizard.detail.valet.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.install_valet".localized,
                learnMoreLink: nil,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: true
            )
        case .continueToStartup:
            return OnboardingActionDescriptor(
                detailTitle: "onboarding_wizard.detail.ready.title".localized,
                detailDescription: "onboarding_wizard.detail.ready.description".localized,
                primaryButtonTitle: "onboarding_wizard.buttons.continue".localized,
                learnMoreLink: nil,
                commandBlock: nil,
                usesStatusBanner: false,
                showsTerminalOutputWhenRunning: false
            )
        }
    }

    private func makeSidebarItems() -> [OnboardingViewState.SidebarItem] {
        let items: [(OnboardingStep, String)] = [
            (.introduction, "onboarding_wizard.steps.introduction".localized),
            (.developerTools, "onboarding_wizard.steps.developer_tools".localized),
            (.homebrew, "onboarding_wizard.steps.homebrew".localized),
            (.phpComposer, "onboarding_wizard.steps.php_composer".localized),
            (.valet, "onboarding_wizard.steps.valet".localized),
            (.ready, "onboarding_wizard.steps.ready".localized)
        ]

        return items.enumerated().map { index, item in
            OnboardingViewState.SidebarItem(
                step: item.0,
                status: stepStatus(for: item.0),
                title: item.1,
                badgeTitle: nil,
                isFirst: index == 0,
                isLast: index == items.count - 1
            )
        }
    }

    private func makeIntroductionItems() -> [OnboardingViewState.IntroductionItem] {
        let items: [(OnboardingStep, String, String)] = [
            (
                .developerTools,
                "onboarding_wizard.steps.developer_tools".localized,
                "onboarding_wizard.intro.developer_tools".localized
            ),
            (
                .homebrew,
                "onboarding_wizard.steps.homebrew".localized,
                "onboarding_wizard.intro.homebrew".localized
            ),
            (
                .phpComposer,
                "onboarding_wizard.steps.php_composer".localized,
                "onboarding_wizard.intro.php_composer".localized
            ),
            (
                .valet,
                "onboarding_wizard.steps.valet".localized,
                "onboarding_wizard.intro.valet".localized
            )
        ]

        return items.enumerated().map { index, item in
            OnboardingViewState.IntroductionItem(
                step: item.0,
                number: index + 1,
                title: item.1,
                badgeTitle: nil,
                description: item.2,
                isCompleted: isStepCompleted(item.0)
            )
        }
    }

    private func progressText(for activeStepNumber: Int?) -> String {
        if currentStep == .introduction {
            return "onboarding_wizard.progress.introduction".localized
        }

        return "onboarding_wizard.progress.step".localized(activeStepNumber ?? 1)
    }

    private func activeStepNumber(for step: OnboardingStep) -> Int? {
        switch step {
        case .introduction:
            return nil
        case .developerTools:
            return 1
        case .homebrew:
            return 2
        case .phpComposer:
            return 3
        case .valet:
            return 4
        case .ready:
            return 5
        }
    }

    private func stepStatus(for step: OnboardingStep) -> StepStatus {
        if currentStep == step {
            switch state {
            case .running:
                return .running
            case .failed:
                return .failed
            case .idle, .waitingForManualCompletion:
                return .active
            }
        }

        return isStepCompleted(step) ? .completed : .pending
    }

    private func isStepCompleted(_ step: OnboardingStep) -> Bool {
        let progress = displayProgress

        switch step {
        case .introduction:
            return hasCompletedIntroduction
        case .developerTools:
            return progress.developerToolsInstalled
        case .homebrew:
            return progress.developerToolsInstalled
                && progress.homebrewInstalled
                && progress.pathConfigured
        case .phpComposer:
            return progress.phpInstalled
                && progress.composerInstalled
        case .valet:
            return skippedValetSetup || progress.valetSetupInstalled
        case .ready:
            return false
        }
    }
}
