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

    init(
        container: Container,
        fake: Bool = false
    ) {
        self.container = container

        self.evaluations = allAvailableWarnings()

        if isRunningSwiftUIPreview || fake {
            /// SwiftUI previews will always list all possible evaluations.
            self.warnings = self.evaluations
        }
    }

    /// Every possible evaluation that can be checked. Each evaluation also
    /// includes a potential automatic fix, but not all evaluations have an
    /// easy fix. This list is loaded from an extension.
    private var evaluations: [Warning] = []

    /// These warnings are the ones that are ready to be displayed.
    @Published public var warnings: [Warning] = []

    /// Thread-safe storage for warnings being evaluated.
    /// When all temporary warnings are set, you may broadcast these changes
    /// and they will be sent to the @Published variable via the main thread.
    private var temporaryWarnings: [Warning] {
        get { _temporaryWarnings.value }
        set { _temporaryWarnings.value = newValue }
    }
    private let _temporaryWarnings = Locked<[Warning]>([])

    public func hasWarnings() -> Bool {
        return !warnings.isEmpty
    }

    @MainActor func evaluateWarnings() {
        Task { await checkEnvironment() }
    }

    @MainActor func clearWarnings() {
        self.warnings = []
    }

    @MainActor func broadcastWarnings() {
        self.warnings = temporaryWarnings
    }

    /**
     Checks the user's environment and checks if any special warnings apply.
     */
    func checkEnvironment() async {
        container.shell.reloadEnvPath()

        await BrewDiagnostics.shared.loadInstalledTaps()

        if ProcessInfo.processInfo.environment["EXTREME_DOCTOR_MODE"] != nil {
            self.temporaryWarnings = self.evaluations
            await self.broadcastWarnings()
            return
        }

        await evaluate()

        // Only rebuild the menu if the app has finished booting
        // (otherwise the menu may become interactive before all checks are done)
        if await Startup.hasFinishedBooting {
            await MainMenu.shared.rebuild()
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

        self.temporaryWarnings = warnings
        await self.broadcastWarnings()
    }
}
