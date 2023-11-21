//
//  PhpVersionManagerView+Interactivity.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

extension PhpVersionManagerView {
    public func runCommand(_ command: ModifyPhpVersionCommand) async {
        if PhpEnvironments.shared.isBusy {
            self.presentErrorAlert(
                title: "phpman.action_prevented_busy.title".localized,
                description: "phpman.action_prevented_busy.desc".localized,
                button: "generic.ok".localized
            )
            return
        }

        do {
            self.setBusyStatus(true)
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1

                    // Whenever a key step is finished, refresh the PHP versions
                    if progress.value == 1 {
                        await self.handler.refreshPhpVersions(loadOutdated: false)
                    }
                }
            }
            // Finally, after completing the command, also refresh PHP versions
            await self.handler.refreshPhpVersions(loadOutdated: false)
            // and mark the app as no longer busy
            self.setBusyStatus(false)
        } catch let error {
            let error = error as! BrewCommandError
            let messages = error.log.suffix(2).joined(separator: "\n")

            self.setBusyStatus(false)
            await self.handler.refreshPhpVersions(loadOutdated: false)

            self.presentErrorAlert(
                title: "phpman.failures.install.title".localized,
                description: "phpman.failures.install.desc".localized(messages),
                button: "generic.ok".localized
            )
        }
    }

    public func repairAll() async {
        await self.runCommand(ModifyPhpVersionCommand(
            title: "phpman.operations.repairing".localized,
            upgrading: [],
            installing: []
        ))
    }

    public func upgradeAll(_ formulae: [BrewPhpFormula]) async {
        await self.runCommand(ModifyPhpVersionCommand(
            title: "phpman.operations.updating".localized,
            upgrading: formulae,
            installing: []
        ))
    }

    public func install(_ formula: BrewPhpFormula) async {
        await self.runCommand(ModifyPhpVersionCommand(
            title: "phpman.operations.installing".localized(formula.displayName),
            upgrading: [],
            installing: [formula]
        ))
    }

    public func confirmUninstall(_ formula: BrewPhpFormula) async {
        // Disallow removal of the currently active versipn
        if formula.installedVersion == PhpEnvironments.shared.currentInstall?.version.text {
            self.presentErrorAlert(
                title: "phpman.uninstall_prevented.title".localized,
                description: "phpman.uninstall_prevented.desc".localized,
                button: "generic.ok".localized
            )
            return
        }

        Alert.confirm(
            onWindow: App.shared.phpVersionManagerWindowController!.window!,
            messageText: "phpman.warnings.removal.title".localized(formula.displayName),
            informativeText: "phpman.warnings.removal.desc".localized(formula.displayName),
            buttonTitle: "phpman.warnings.removal.button".localized,
            buttonIsDestructive: true,
            secondButtonTitle: "generic.cancel".localized,
            style: .warning,
            onFirstButtonPressed: {
                Task { await self.uninstall(formula) }
            }
        )
    }

    public func uninstall(_ formula: BrewPhpFormula) async {
        let command = RemovePhpVersionCommand(formula: formula.name)

        do {
            self.setBusyStatus(true)
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1

                    if progress.value == 1 {
                        await self.handler.refreshPhpVersions(loadOutdated: false)
                        self.setBusyStatus(false)
                    }
                }
            }
        } catch {
            self.setBusyStatus(false)
            self.presentErrorAlert(
                title: "phpman.failures.uninstall.title".localized,
                description: "phpman.failures.uninstall.desc".localized(
                    "brew uninstall \(formula.name) --force"
                ),
                button: "generic.ok".localized
            )
        }
    }

    public func setBusyStatus(_ busy: Bool) {
        Task { @MainActor in
            PhpEnvironments.shared.isBusy = busy
            self.status.busy = busy
        }
    }

    public func presentErrorAlert(
        title: String,
        description: String,
        button: String,
        style: NSAlert.Style = .critical
    ) {
        Alert.confirm(
            onWindow: App.shared.phpVersionManagerWindowController!.window!,
            messageText: title,
            informativeText: description,
            buttonTitle: button,
            secondButtonTitle: "",
            style: style,
            onFirstButtonPressed: {}
        )
    }

    var hasUpdates: Bool {
        return self.formulae.phpVersions.contains { formula in
            return formula.hasUpgrade
        }
    }
}
