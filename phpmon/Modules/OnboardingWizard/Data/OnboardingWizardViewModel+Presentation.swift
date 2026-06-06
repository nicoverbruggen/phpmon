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

    enum StatusBannerSeverity: Equatable {
        case info
        case warning
    }

    struct StatusBanner: Equatable {
        let text: String
        let severity: StatusBannerSeverity
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

    var statusBannerSeverity: OnboardingViewState.StatusBannerSeverity? {
        return viewState.statusBanner?.severity
    }

    var showsTerminalOutput: Bool {
        return viewState.showsTerminalOutput
    }

    var viewState: OnboardingViewState {
        let descriptor = descriptor(for: action)
        let activeStepNumber = activeStepNumber(for: currentStep)
        let latestOutputLine = outputLines
            .reversed()
            .first(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })

        let statusBanner = descriptor.usesStatusBanner && latestOutputLine != nil
            ? OnboardingViewState.StatusBanner(
                text: latestOutputLine?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                severity: statusBannerSeverity(for: latestOutputLine)
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
                && (state == .running || state == .failed)
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
            return .startSetup()
        case .installDeveloperTools:
            return .installDeveloperTools()
        case .recheckDeveloperTools:
            return .recheckDeveloperTools()
        case .installHomebrew:
            return .installHomebrew()
        case .recheckHomebrew:
            return .recheckHomebrew()
        case .fixPathAutomatically:
            return .fixPathAutomatically()
        case .recheckPath:
            return .recheckPath(
                configuredShellPath: container.paths.configuredShellPath,
                instructionLines: ShellEnvironment(container).pathInstructionLines()
            )
        case .installPhpComposer:
            return .installPhpComposer()
        case .installValet:
            return .installValet()
        case .continueToStartup:
            return .continueToStartup()
        }
    }

    private func statusBannerSeverity(for outputLine: OutputLine?) -> OnboardingViewState.StatusBannerSeverity {
        let outputText = outputLine?.text.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (state, outputText) {
        case (.failed, _),
            (_, "onboarding_wizard.output.step_not_resolved".localized):
            return .warning
        default:
            return .info
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
        let items: [IntroductionItemDescriptor] = [
            IntroductionItemDescriptor(
                step: .developerTools,
                title: "onboarding_wizard.steps.developer_tools".localized,
                description: "onboarding_wizard.intro.developer_tools".localized
            ),
            IntroductionItemDescriptor(
                step: .homebrew,
                title: "onboarding_wizard.steps.homebrew".localized,
                description: "onboarding_wizard.intro.homebrew".localized
            ),
            IntroductionItemDescriptor(
                step: .phpComposer,
                title: "onboarding_wizard.steps.php_composer".localized,
                description: "onboarding_wizard.intro.php_composer".localized
            ),
            IntroductionItemDescriptor(
                step: .valet,
                title: "onboarding_wizard.steps.valet".localized,
                description: "onboarding_wizard.intro.valet".localized
            )
        ]

        return items.enumerated().map { index, item in
            OnboardingViewState.IntroductionItem(
                step: item.step,
                number: index + 1,
                title: item.title,
                badgeTitle: nil,
                description: item.description,
                isCompleted: isStepCompleted(item.step)
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
