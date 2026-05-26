//
//  OnboardingWizardViewModel.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

@MainActor
class OnboardingWizardViewModel: ObservableObject {
    let container: Container
    private let flow: any OnboardingFlowDefinition
    private let probe: OnboardingEnvironmentProbe
    private let stepRunner: OnboardingStepRunner
    private var alertObservers: [UUID: AsyncStream<OnboardingAlertState>.Continuation] = [:]

    var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?

    @Published var state: OnboardingRunState
    @Published var outputLines: [OutputLine]
    @Published var alertState: OnboardingAlertState?
    @Published private(set) var progress: OnboardingProgress
    @Published private(set) var hasCompletedIntroduction: Bool
    @Published private(set) var hasLoaded: Bool
    @Published private(set) var skippedValetSetup: Bool

    init(
        container: Container = App.shared.container,
        flow: any OnboardingFlowDefinition = FullSetupOnboardingFlow(),
        progress: OnboardingProgress = OnboardingProgress(),
        state: OnboardingRunState = .idle,
        outputLines: [OutputLine] = [],
        alertState: OnboardingAlertState? = nil,
        hasCompletedIntroduction: Bool? = nil,
        hasLoaded: Bool = false,
        skippedValetSetup: Bool = false
    ) {
        self.container = container
        self.flow = flow
        self.probe = OnboardingEnvironmentProbe(container: container)
        self.stepRunner = OnboardingStepRunner(
            container: container,
            probe: OnboardingEnvironmentProbe(container: container)
        )
        self.progress = progress
        self.state = state
        self.outputLines = outputLines
        self.alertState = alertState
        self.hasCompletedIntroduction = hasCompletedIntroduction ?? (flow.entryStep != .introduction)
        self.hasLoaded = hasLoaded
        self.skippedValetSetup = skippedValetSetup
    }

    var displayProgress: OnboardingProgress {
        progress.overlayingForDisplay(with: flow.displayBaseline)
    }

    var completedSteps: Set<OnboardingStep> {
        var steps = Set<OnboardingStep>()
        let progress = displayProgress

        if hasCompletedIntroduction {
            steps.insert(.introduction)
        }

        if progress.developerToolsInstalled {
            steps.insert(.developerTools)
        }

        if progress.homebrewInstalled && progress.pathConfigured {
            steps.insert(.homebrew)
        }

        if progress.phpInstalled && progress.composerInstalled {
            steps.insert(.phpComposer)
        }

        if progress.valetSetupInstalled || skippedValetSetup {
            steps.insert(.valet)
        }

        return steps
    }

    var currentStep: OnboardingStep {
        if !hasCompletedIntroduction {
            return .introduction
        }

        if !progress.developerToolsInstalled {
            return .developerTools
        }

        if !progress.homebrewInstalled || !progress.pathConfigured {
            return .homebrew
        }

        if !progress.phpInstalled || !progress.composerInstalled {
            return .phpComposer
        }

        if skippedValetSetup {
            return .ready
        }

        if !progress.valetSetupInstalled {
            return .valet
        }

        return .ready
    }

    var action: OnboardingAction {
        switch currentStep {
        case .introduction:
            return .startSetup
        case .developerTools:
            return state == .waitingForManualCompletion
                ? .recheckDeveloperTools
                : .installDeveloperTools
        case .homebrew:
            if !progress.homebrewInstalled {
                return state == .waitingForManualCompletion
                    ? .recheckHomebrew
                    : .installHomebrew
            }

            if shouldAutoFixPath && state != .waitingForManualCompletion {
                return .fixPathAutomatically
            }

            return .recheckPath
        case .phpComposer:
            return .installPhpComposer
        case .valet:
            return .installValet
        case .ready:
            return .continueToStartup
        }
    }

    private var shouldAutoFixPath: Bool {
        let shellEnvironment = ShellEnvironment(container)
        return shellEnvironment.isConfiguredShellValid
            && shellEnvironment.resolvedShell.hasSuffix("/zsh")
    }

    func loadIfNeeded() async {
        guard !hasLoaded else {
            return
        }

        applyProgress(await probe.detectProgress())
        hasLoaded = true
    }

    @discardableResult
    func performPrimaryAction() -> Task<Void, Never>? {
        guard hasLoaded else {
            return nil
        }

        switch action {
        case .startSetup:
            hasCompletedIntroduction = true
            return nil
        case .continueToStartup:
            onComplete?(skippedValetSetup ? .completedInStandaloneMode : .completed)
            return nil
        default:
            let currentAction = action
            outputLines = []
            state = .running

            return Task { [weak self] in
                guard let self else {
                    return
                }

                let result = await self.stepRunner.run(currentAction) { [weak self] line in
                    Task { @MainActor in
                        self?.outputLines.append(line)
                    }
                }
                await MainActor.run {
                    self.state = result.state
                    self.outputLines = result.outputLines

                    if let progress = result.progress {
                        self.applyProgress(progress)
                    }

                    if let alertState = result.alertState {
                        self.presentAlert(alertState)
                    }
                }
            }
        }
    }

    func skip() {
        onComplete?(.skipped)
    }

    func requestSkipConfirmation() {
        presentAlert(.skipConfirmation)
    }

    func requestSkipValetConfirmation() {
        presentAlert(.skipValetConfirmation)
    }

    func dismissAlert() {
        alertState = nil
    }

    func observeAlerts() -> AsyncStream<OnboardingAlertState> {
        let observerID = UUID()

        return AsyncStream { continuation in
            alertObservers[observerID] = continuation

            if let alertState {
                continuation.yield(alertState)
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.alertObservers.removeValue(forKey: observerID)
                }
            }
        }
    }

    func confirmSkipCurrentAlert() {
        guard let alertState else {
            return
        }

        switch alertState {
        case .skipConfirmation:
            dismissAlert()
            skip()
        case .skipValetConfirmation:
            dismissAlert()
            skipValetSetup()
        case .developerToolsIncomplete, .valetSudoersCleanupFailed:
            dismissAlert()
        }
    }

    func skipValetSetup() {
        skippedValetSetup = true
        outputLines = []
        state = .idle

        if container === App.shared.container {
            Valet.shared.installed = false
        }
    }

    private func applyProgress(_ progress: OnboardingProgress) {
        self.progress = progress

        if container === App.shared.container {
            Valet.shared.installed = progress.valetInstalled

            if App.hasLoadedTestableConfiguration && progress.valetInstalled {
                ValetScanner.useFake()
                ValetInteractor.useFake()
            }
        }
    }

    private func presentAlert(_ alertState: OnboardingAlertState) {
        self.alertState = alertState

        for observer in alertObservers.values {
            observer.yield(alertState)
        }
    }
}
