//
//  MainMenu+Composer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert
import ContainerMacro

@ContainerAccess
@MainActor class ComposerWindow {
    private var shouldNotify: Bool! = nil
    private var completion: ((Bool) -> Void)! = nil
    private var window: TerminalProgressWindowController?

    /**
     Updates the global dependencies and runs the completion callback when done.
     */
    func updateGlobalDependencies(notify: Bool, completion: @escaping (Bool) -> Void) {
        self.shouldNotify = notify
        self.completion = completion

        container.paths.detectBinaryPaths()

        if container.paths.composer == nil {
            self.presentMissingAlert()
            return
        }

        phpEnvs.isBusy = true

        window = TerminalProgressWindowController.display(
            title: "alert.composer_progress.title".localized,
            description: "alert.composer_progress.info".localized
        )

        window?.setType(info: true)

        Task { // Start the Composer global update as a separate task
            await performComposerUpdate()
        }
    }

    private func performComposerUpdate() async {
        do {
            try await runComposerUpdateShellCommand()
        } catch {
            composerUpdateFailed()
        }
    }

    private func runComposerUpdateShellCommand() async throws {
        let command = "\(container.paths.composer!) global update"

        self.window?.addToConsole("\(command)\n")

        let (process, _) = try await shell.attach(
            command,
            didReceiveOutput: { [weak self] (incoming, _) in
                guard let window = self?.window else { return }
                window.addToConsole(incoming)
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus <= 0 {
            composerUpdateSucceeded()
        } else {
            composerUpdateFailed()
        }
    }

    private func composerUpdateSucceeded() {
        // Closing the window should happen after a slight delay
        Task { @MainActor in
            await delay(seconds: 1.0)
            window?.close()
            if shouldNotify {
                LocalNotification.send(
                    title: "alert.composer_success.title".localized,
                    subtitle: "alert.composer_success.info".localized,
                    preference: .notifyAboutGlobalComposerStatus
                )
            }
            window = nil

            // Update the internal Valet number because it may have updated
            await Valet.shared.updateVersionNumber()

            // Update the UI
            removeBusyStatus()

            // Fire completion callback
            completion(true)
        }
    }

    private func composerUpdateFailed() {
        // Showing that something failed should be shown immediately
        Task { @MainActor [self] in
            window?.setType(info: false)
            window?.progressView?.labelTitle.stringValue = "alert.composer_failure.title".localized
            window?.progressView?.labelDescription.stringValue = "alert.composer_failure.info".localized
            window = nil
            removeBusyStatus()
            completion(false)
        }
    }

    // MARK: Main Menu Update

    private func removeBusyStatus() {
        phpEnvs.isBusy = false
    }

    // MARK: Alert

    private func presentMissingAlert() {
        NVAlert()
            .withInformation(
                title: "alert.composer_missing.title".localized,
                subtitle: "alert.composer_missing.subtitle".localized,
                description: "alert.composer_missing.desc".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }
}
