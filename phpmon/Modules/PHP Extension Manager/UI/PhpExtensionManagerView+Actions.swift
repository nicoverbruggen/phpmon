//
//  PhpExtensionManagerView+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

extension PhpExtensionManagerView {
    public func presentErrorAlert(
        title: String,
        description: String,
        button: String,
        style: NSAlert.Style = .critical
    ) {
        Alert.confirm(
            onWindow: App.shared.phpExtensionManagerWindowController!.window!,
            messageText: title,
            informativeText: description,
            buttonTitle: button,
            secondButtonTitle: "",
            style: style,
            onFirstButtonPressed: {}
        )
    }

    public func install(_ ext: BrewPhpExtension) {
        Task {
            await self.runCommand(InstallPhpExtensionCommand(install: [ext]))
        }
    }

    public func confirmUninstall(_ ext: BrewPhpExtension) {
        Alert.confirm(
            onWindow: App.shared.phpExtensionManagerWindowController!.window!,
            messageText: "phpextman.warnings.removal.title".localized(ext.name),
            informativeText: "phpextman.warnings.removal.desc".localized(ext.name),
            buttonTitle: "phpextman.warnings.removal.button".localized,
            buttonIsDestructive: true,
            secondButtonTitle: "generic.cancel".localized,
            style: .warning,
            onFirstButtonPressed: {
                Task {
                    await self.runCommand(RemovePhpExtensionCommand(remove: ext))
                }
            }
        )
    }

    public func runCommand(_ command: BrewCommand) async {
        if PhpEnvironments.shared.isBusy {
            self.presentErrorAlert(
                title: "phpman.action_prevented_busy.title".localized,
                description: "phpman.action_prevented_busy.desc".localized,
                button: "generic.ok".localized
            )
            return
        }

        do {
            self.status.busy = true
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1
                }
            }

            self.manager.loadExtensionData(for: self.phpVersion)
            self.status.busy = false
        } catch let error {
            let error = error as! BrewCommandError
            let messages = error.log.suffix(2).joined(separator: "\n")

            self.status.busy = false

            self.presentErrorAlert(
                title: "phpman.failures.install.title".localized,
                description: "phpman.failures.install.desc".localized(messages),
                button: "generic.ok".localized
            )
        }
    }
}
