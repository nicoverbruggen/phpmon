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
    }

    enum Action: Equatable {
        case installDeveloperTools
        case recheckDeveloperTools
        case installHomebrew
        case fixPathAutomatically
        case recheckPath
        case installPhpComposer
        case continueToStartup
    }

    let container: Container
    var onComplete: ((Startup.OnboardingWizardOutcome) -> Void)?
    var onDeveloperToolsRecheckFailed: (() -> Void)?

    @Published var state: State
    @Published var outputLines: [OutputLine]
    @Published private(set) var progress: StepProgress
    @Published private(set) var hasLoaded: Bool

    var hasTriggeredDeveloperToolsInstall = false

    init(
        container: Container = App.shared.container,
        progress: StepProgress = StepProgress(),
        state: State = .idle,
        outputLines: [OutputLine] = [],
        hasLoaded: Bool = false
    ) {
        self.container = container
        self.progress = progress
        self.state = state
        self.outputLines = outputLines
        self.hasLoaded = hasLoaded
    }

    var completedSteps: Set<Int> {
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

        return steps
    }

    var primaryButtonDisabled: Bool {
        return !hasLoaded || state == .running
    }

    var showsOutput: Bool {
        return !outputLines.isEmpty
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
            return Task { await installHomebrew() }
        case .fixPathAutomatically:
            return Task { await fixPathAutomatically() }
        case .recheckPath:
            return Task { await recheckPath() }
        case .installPhpComposer:
            return Task { await installPhpComposer() }
        case .continueToStartup:
            onComplete?(.completed)
            return nil
        }
    }

    func quit() {
        onComplete?(.quit)
    }

    func clearOutput() {
        outputLines = []
    }

    var action: Action {
        if !progress.developerToolsInstalled {
            return hasTriggeredDeveloperToolsInstall ? .recheckDeveloperTools : .installDeveloperTools
        }

        if !progress.homebrewInstalled {
            return .installHomebrew
        }

        if !progress.pathConfigured {
            return shouldAutoFixPath ? .fixPathAutomatically : .recheckPath
        }

        if !progress.phpInstalled || !progress.composerInstalled {
            return .installPhpComposer
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

        progress = StepProgress(
            developerToolsInstalled: await toolchain.status(.commandLineTools).installed,
            homebrewInstalled: await toolchain.status(.homebrew).installed,
            pathConfigured: shellEnvironment.hasRequiredOnboardingPaths(),
            phpInstalled: await toolchain.status(.php).installed,
            composerInstalled: await toolchain.status(.composer).installed
        )
    }

    func appendOutput(_ text: String, _ stream: ShellStream) {
        outputLines.append(OutputLine(text: text, stream: stream))
    }
}
