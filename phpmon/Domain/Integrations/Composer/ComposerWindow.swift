//
//  MainMenu+Composer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ComposerWindow {

    private var menu: MainMenu?
    private var shouldNotify: Bool! = nil
    private var completion: ((Bool) -> Void)! = nil
    private var window: TerminalProgressWindowController?

    /**
     Updates the global dependencies and runs the completion callback when done.
     */
    func updateGlobalDependencies(notify: Bool, completion: @escaping (Bool) -> Void) {
        self.menu = MainMenu.shared
        self.shouldNotify = notify
        self.completion = completion

        Paths.shared.detectBinaryPaths()
        if Paths.composer == nil {
            DispatchQueue.main.async {
                self.presentMissingAlert()
            }
            return
        }

        PhpEnv.shared.isBusy = true
        menu?.setBusyImage()
        menu?.rebuild()

        window = TerminalProgressWindowController.display(
            title: "alert.composer_progress.title".localized,
            description: "alert.composer_progress.info".localized
        )

        window?.setType(info: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let task = Shell.user.createTask(
                for: "\(Paths.composer!) global update", requiresPath: true
            )

            DispatchQueue.main.async {
                self.window?.addToConsole("\(Paths.composer!) global update\n")
            }

            task.listen(
                didReceiveStandardOutputData: { [weak self] string in
                    DispatchQueue.main.async {
                        self?.window?.addToConsole(string)
                    }
                    // Log.perf("\(string.trimmingCharacters(in: .newlines))")
                },
                didReceiveStandardErrorData: { [weak self] string in
                    DispatchQueue.main.async {
                        self?.window?.addToConsole(string)
                    }
                    // Log.perf("\(string.trimmingCharacters(in: .newlines))")
                }
            )

            task.launch()
            task.waitUntilExit()
            task.haltListening()

            if task.terminationStatus <= 0 {
                composerUpdateSucceeded()
            } else {
                composerUpdateFailed()
            }
        }
    }

    private func composerUpdateSucceeded() {
        // Closing the window should happen after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            window?.close()
            if shouldNotify {
                LocalNotification.send(
                    title: "alert.composer_success.title".localized,
                    subtitle: "alert.composer_success.info".localized,
                    preference: .notifyAboutGlobalComposerStatus
                )
            }
            window = nil
            removeBusyStatus()
            menu = nil
            completion(true)
        }
    }

    private func composerUpdateFailed() {
        // Showing that something failed should be shown immediately
        DispatchQueue.main.async { [self] in
            window?.setType(info: false)
            window?.progressView?.labelTitle.stringValue = "alert.composer_failure.title".localized
            window?.progressView?.labelDescription.stringValue = "alert.composer_failure.info".localized
            window = nil
            removeBusyStatus()
            menu = nil
            completion(false)
        }
    }

    // MARK: Main Menu Update

    private func removeBusyStatus() {
        PhpEnv.shared.isBusy = false
        menu?.updatePhpVersionInStatusBar()
    }

    // MARK: Alert

    @MainActor private func presentMissingAlert() {
        BetterAlert()
            .withInformation(
                title: "alert.composer_missing.title".localized,
                subtitle: "alert.composer_missing.subtitle".localized,
                description: "alert.composer_missing.desc".localized
            )
            .withPrimary(text: "OK")
            .show()
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }
}
