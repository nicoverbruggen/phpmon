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
    let entryMode: OnboardingEntryMode
    private let flow: any OnboardingFlowDefinition
    var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?
    var onDeveloperToolsRecheckFailed: (() -> Void)?
    var onValetSudoersRemovalFailed: (() -> Void)?

    @Published var state: State
    @Published var outputLines: [OutputLine]
    @Published private(set) var progress: StepProgress
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
        hasLoaded: Bool = false,
        skippedValetSetup: Bool = false
    ) {
        self.container = container
        self.flow = flow
        self.entryMode = flow.entryMode
        self.progress = progress
        self.state = state
        self.outputLines = outputLines
        self.hasLoaded = hasLoaded
        self.skippedValetSetup = skippedValetSetup
    }

    var displayProgress: StepProgress {
        progress.overlayingForDisplay(with: flow.displayBaseline)
    }

    var completedSteps: Set<Int> {
        let progress = displayProgress
        var steps = Set<Int>()

        if progress.developerToolsInstalled {
            steps.insert(1)
        }

        if progress.homebrewInstalled && progress.pathConfigured {
            steps.insert(2)
        }

        if progress.phpInstalled && progress.composerInstalled {
            steps.insert(3)
        }

        if progress.valetSetupInstalled || skippedValetSetup {
            steps.insert(4)
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
        default:
            return false
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }

        await refreshProgress()
        hasLoaded = true
    }

    @discardableResult
    func performPrimaryAction() -> Task<Void, Never>? {
        guard hasLoaded else { return nil }

        switch action {
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
        if !progress.developerToolsInstalled {
            return hasTriggeredDeveloperToolsInstall ? .recheckDeveloperTools : .installDeveloperTools
        }

        if !progress.homebrewInstalled {
            return hasTriggeredHomebrewInstall ? .recheckHomebrew : .installHomebrew
        }

        if !progress.pathConfigured {
            return shouldAutoFixPath ? .fixPathAutomatically : .recheckPath
        }

        if !progress.phpInstalled || !progress.composerInstalled {
            return .installPhpComposer
        }

        if skippedValetSetup {
            return .continueToStartup
        }

        if !progress.valetSetupInstalled {
            return .installValet
        }

        return .continueToStartup
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
            .pipe("cat /private/etc/sudoers.d/brew")
            .out.contains(container.paths.brew)
        let valetTrusted = await container.shell
            .pipe("cat /private/etc/sudoers.d/valet")
            .out.contains(container.paths.valet)

        return brewTrusted && valetTrusted
    }
}
