//
//  WarningManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class WarningManager: ObservableObject {

    var container: Container
    let brewDiagnostics: BrewDiagnostics
    let phpConfigChecker: PhpConfigChecker

    init(
        container: Container,
        fake: Bool = false
    ) {
        self.container = container
        self.brewDiagnostics = BrewDiagnostics(container)
        self.phpConfigChecker = PhpConfigChecker(container)

        self.evaluations = allAvailableWarnings()

        if isRunningSwiftUIPreview || fake {
            /// SwiftUI previews will always list all possible evaluations.
            self.warnings = self.evaluations
            self.hasCompletedInitialEvaluation = true
        }
    }

    /// Every possible evaluation that can be checked. Each evaluation also
    /// includes a potential automatic fix, but not all evaluations have an
    /// easy fix. This list is loaded from an extension.
    private var evaluations: [Warning] = []

    /// These warnings are the ones that are ready to be displayed.
    @Published public var warnings: [Warning] = []

    /// An empty result is meaningful only after the first evaluation has finished.
    @Published private(set) var hasCompletedInitialEvaluation = false

    public func hasWarnings() -> Bool {
        return !warnings.isEmpty
    }

    @MainActor func evaluateWarnings() {
        Task { await checkEnvironment() }
    }

    @MainActor func clearWarnings() {
        self.warnings = []
        self.hasCompletedInitialEvaluation = true
    }

    /**
     Checks the user's environment and checks if any special warnings apply.
     */
    func checkEnvironment() async {
        await container.shell.reloadEnvPath()

        await brewDiagnostics.loadInstalledTaps()
        await brewDiagnostics.loadTrustedTaps()

        if ProcessInfo.processInfo.environment["EXTREME_DOCTOR_MODE"] != nil {
            self.warnings = self.evaluations
            self.hasCompletedInitialEvaluation = true
            return
        }

        await evaluate()

        // Only rebuild the menu if the app has finished booting
        // (otherwise the menu may become interactive before all checks are done)
        if Startup.hasFinishedBooting {
            MainMenu.shared.rebuild()
        }
    }

    /**
     Runs through all evaluations and appends any applicable warning results.
     Will automatically broadcast these warnings.
     */
    private func evaluate() async {
        var warnings: [Warning] = []

        for check in self.evaluations where await check.applies() {
            Log.info("[DOCTOR] \(check.name) (!)")
            warnings.append(check)
        }

        self.warnings = warnings
        self.hasCompletedInitialEvaluation = true
    }
}
