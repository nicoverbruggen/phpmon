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
    enum Step: Hashable {
        case introduction
        case developerTools
        case homebrew
        case phpComposer
        case valet
        case ready
    }

    enum State: Equatable {
        case idle
        case running
        case waitingForManualCompletion
        case failed
    }

    struct StepProgress: Equatable {
        var developerToolsInstalled: Bool = false
        var homebrewInstalled: Bool = false
        var pathConfigured: Bool = false
        var phpInstalled: Bool = false
        var composerInstalled: Bool = false
        var valetInstalled: Bool = false
        var valetTrusted: Bool = false

        var coreToolingInstalled: Bool {
            developerToolsInstalled
                && homebrewInstalled
                && pathConfigured
                && phpInstalled
                && composerInstalled
        }

        var valetSetupInstalled: Bool {
            valetInstalled && valetTrusted
        }

        func overlayingForDisplay(with baseline: StepProgress) -> StepProgress {
            return StepProgress(
                developerToolsInstalled: developerToolsInstalled || baseline.developerToolsInstalled,
                homebrewInstalled: homebrewInstalled || baseline.homebrewInstalled,
                pathConfigured: pathConfigured || baseline.pathConfigured,
                phpInstalled: phpInstalled || baseline.phpInstalled,
                composerInstalled: composerInstalled || baseline.composerInstalled,
                valetInstalled: valetInstalled || baseline.valetInstalled,
                valetTrusted: valetTrusted || baseline.valetTrusted
            )
        }
    }

    enum Action: Equatable {
        case startSetup
        case installDeveloperTools
        case recheckDeveloperTools
        case installHomebrew
        case recheckHomebrew
        case fixPathAutomatically
        case recheckPath
        case installPhpComposer
        case installValet
        case continueToStartup
    }

    let container: Container
    private let flow: any OnboardingFlowDefinition
    var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?
    var onDeveloperToolsRecheckFailed: (() -> Void)?
    var onValetSudoersRemovalFailed: (() -> Void)?

    @Published var state: State
    @Published var outputLines: [OutputLine]
    @Published private(set) var progress: StepProgress
    @Published private(set) var hasCompletedIntroduction: Bool
    @Published private(set) var hasLoaded: Bool
    @Published private(set) var skippedValetSetup: Bool

    var hasTriggeredDeveloperToolsInstall = false
    var hasTriggeredHomebrewInstall = false

    init(
        container: Container = App.shared.container,
        flow: any OnboardingFlowDefinition = FullSetupOnboardingFlow(),
        progress: StepProgress = StepProgress(),
        state: State = .idle,
        outputLines: [OutputLine] = [],
        hasCompletedIntroduction: Bool? = nil,
        hasLoaded: Bool = false,
        skippedValetSetup: Bool = false
    ) {
        self.container = container
        self.flow = flow
        self.progress = progress
        self.state = state
        self.outputLines = outputLines
        self.hasCompletedIntroduction = hasCompletedIntroduction ?? (flow.entryStep != .introduction)
        self.hasLoaded = hasLoaded
        self.skippedValetSetup = skippedValetSetup
    }

    var displayProgress: StepProgress {
        progress.overlayingForDisplay(with: flow.displayBaseline)
    }

    var completedSteps: Set<Step> {
        let progress = displayProgress
        var steps = Set<Step>()

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

    var primaryButtonDisabled: Bool {
        return !hasLoaded || state == .running
    }

    var showsOutput: Bool {
        return !outputLines.isEmpty
    }

    var shouldShowTerminalOutput: Bool {
        switch action {
        case .installPhpComposer, .installValet:
            return state == .running
        case .startSetup, .installDeveloperTools, .recheckDeveloperTools, .installHomebrew,
            .recheckHomebrew, .fixPathAutomatically, .recheckPath, .continueToStartup:
            return false
        }
    }

    var currentStep: Step {
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

    func loadIfNeeded() async {
        guard !hasLoaded else { return }

        await refreshProgress()
        hasLoaded = true
    }

    @discardableResult
    func performPrimaryAction() -> Task<Void, Never>? {
        guard hasLoaded else { return nil }

        return makeTaskForCurrentAction()
    }

    private func makeTaskForCurrentAction() -> Task<Void, Never>? {
        switch action {
        case .startSetup:
            completeIntroduction()
            return nil
        case .installDeveloperTools:
            return Task { await requestDeveloperToolsInstall() }
        case .recheckDeveloperTools:
            return Task { await recheckDeveloperTools() }
        case .installHomebrew:
            return Task { await requestHomebrewInstall() }
        case .recheckHomebrew:
            return Task { await recheckHomebrew() }
        case .fixPathAutomatically:
            return Task { await fixPathAutomatically() }
        case .recheckPath:
            return Task { await recheckPath() }
        case .installPhpComposer:
            return Task { await installPhpComposer() }
        case .installValet:
            return Task { await installValet() }
        case .continueToStartup:
            onComplete?(skippedValetSetup ? .completedInStandaloneMode : .completed)
            return nil
        }
    }

    func skip() {
        onComplete?(.skipped)
    }

    func completeIntroduction() {
        hasCompletedIntroduction = true
    }

    func skipValetSetup() {
        skippedValetSetup = true
        outputLines = []
        state = .idle

        if container === App.shared.container {
            Valet.shared.installed = false
        }
    }

    func clearOutput() {
        outputLines = []
    }

    func completeCurrentStep() {
        outputLines = []
        state = .idle
    }

    var action: Action {
        switch currentStep {
        case .introduction:
            return .startSetup
        case .developerTools:
            return hasTriggeredDeveloperToolsInstall ? .recheckDeveloperTools : .installDeveloperTools
        case .homebrew:
            if !progress.homebrewInstalled {
                return hasTriggeredHomebrewInstall ? .recheckHomebrew : .installHomebrew
            }

            return shouldAutoFixPath ? .fixPathAutomatically : .recheckPath
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

    func refreshProgress() async {
        let toolchain = Toolchain(container)
        let shellEnvironment = ShellEnvironment(container)
        let valetInstalled = hasValetBinary() && hasValetConfiguration()
        let valetTrusted = await hasValetTrustConfiguration()

        progress = StepProgress(
            developerToolsInstalled: await toolchain.status(.commandLineTools).installed,
            homebrewInstalled: await toolchain.status(.homebrew).installed,
            pathConfigured: shellEnvironment.hasRequiredOnboardingPaths(),
            phpInstalled: await toolchain.status(.php).installed,
            composerInstalled: await toolchain.status(.composer).installed,
            valetInstalled: valetInstalled,
            valetTrusted: valetTrusted
        )

        if container === App.shared.container {
            Valet.shared.installed = valetInstalled

            if App.hasLoadedTestableConfiguration && valetInstalled {
                ValetScanner.useFake()
                ValetInteractor.useFake()
            }
        }
    }

    func appendOutput(_ text: String, _ stream: ShellStream) {
        outputLines.append(OutputLine(text: text, stream: stream))
    }

    private func hasValetBinary() -> Bool {
        return container.filesystem.fileExists(container.paths.valet)
            || container.filesystem.fileExists("~/.composer/vendor/bin/valet")
    }

    private func hasValetConfiguration() -> Bool {
        return container.filesystem.directoryExists("~/.config/valet")
    }

    private func hasValetTrustConfiguration() async -> Bool {
        let brewTrusted = await container.shell
            .pipe(Toolchain.Commands.checkSudoersBrew)
            .out.contains(container.paths.brew)
        let valetTrusted = await container.shell
            .pipe(Toolchain.Commands.checkSudoersValet)
            .out.contains(container.paths.valet)

        return brewTrusted && valetTrusted
    }
}
