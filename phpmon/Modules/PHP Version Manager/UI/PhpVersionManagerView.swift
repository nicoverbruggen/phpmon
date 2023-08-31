//
//  PhpVersionManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

// swiftlint:disable type_body_length
struct PhpVersionManagerView: View {
    @ObservedObject var formulae: BrewFormulaeObservable
    @ObservedObject var status: PhpFormulaeStatus
    var handler: HandlesBrewFormulae

    init(
        formulae: BrewFormulaeObservable,
        handler: HandlesBrewFormulae
    ) {
        self.formulae = formulae
        self.handler = handler

        self.status = PhpFormulaeStatus(
            busy: true,
            title: "phpman.busy.title".localized,
            description: "phpman.busy.description.outdated".localized
        )

        Task { [self] in
            await self.initialLoad()
        }
    }

    private func initialLoad() async {
        guard let version = Brew.shared.version else {
            return
        }

        await delay(seconds: 1)

        if version.major != 4 {
            Task { @MainActor in
                self.presentErrorAlert(
                    title: "phpman.warnings.unsupported.title".localized,
                    description: "phpman.warnings.unsupported.desc".localized(version.text),
                    button: "generic.ok".localized,
                    style: .warning
                )
            }
        }

        await PhpEnvironments.detectPhpVersions()
        await self.handler.refreshPhpVersions(loadOutdated: false)
        await self.handler.refreshPhpVersions(loadOutdated: true)
        self.status.busy = false
    }

    private func reload() async {
        Task { @MainActor in
            self.status.busy = true
            self.status.title = "phpman.busy.title".localized
            self.status.description = "phpman.busy.description.outdated".localized
        }
        await self.handler.refreshPhpVersions(loadOutdated: true)
        Task { @MainActor in
            self.status.busy = false
        }
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: "arrow.down.to.line.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.blue)
                    .padding(12)
                VStack(alignment: .leading, spacing: 5) {
                    Text("phpman.description".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("phpman.disclaimer".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)

            if self.hasUpdates {
                Divider()
                HStack(alignment: .center, spacing: 15) {
                    Text("phpman.has_updates.description".localizedForSwiftUI)
                        .foregroundColor(.gray)
                        .font(.system(size: 11))

                    Button("phpman.has_updates.button".localizedForSwiftUI, action: {
                        Task { await self.upgradeAll(self.formulae.upgradeable) }

                    })
                    .focusable(false)
                    .disabled(self.status.busy)
                }
                .padding(10)
            } else {
                Divider()

                HStack(alignment: .center, spacing: 15) {
                    Button {
                        Task { await self.reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .buttonStyle(.automatic)
                            .controlSize(.large)
                    }
                    .focusable(false)
                    .disabled(self.status.busy)

                    Text("phpman.refresh.button.description".localizedForSwiftUI)
                        .foregroundColor(.gray)
                        .font(.system(size: 11))
                }
                .padding(10)
            }

            BlockingOverlayView(busy: self.status.busy, title: self.status.title, text: self.status.description) {
                List(Array(formulae.phpVersions.enumerated()), id: \.1.name) { (index, formula) in
                    HStack {
                        Image(systemName: formula.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(formula.iconColor)
                            .padding(.horizontal, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(formula.displayName).bold()

                                if formula.prerelease {
                                    Text("phpman.version.prerelease".localized.uppercased())
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.appPrimary)
                                        .foregroundColor(Color.white)
                                        .clipShape(Capsule())
                                        .fixedSize(horizontal: true, vertical: true)
                                        .frame(maxHeight: 7)
                                }
                            }

                            if formula.isInstalled && formula.hasUpgrade {
                                Text("phpman.version.has_update".localized(
                                    formula.installedVersion!,
                                    formula.upgradeVersion!
                                ))
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            } else if formula.isInstalled && formula.installedVersion != nil {
                                Text("phpman.version.installed".localized(formula.installedVersion!))
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            } else {
                                Text("phpman.version.available_for_installation".localizedForSwiftUI)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            if !formula.healthy {
                                Text("phpman.version.broken".localizedForSwiftUI)
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if !formula.healthy {
                            Button("phpman.buttons.repair".localizedForSwiftUI, role: .destructive) {
                                Task { await self.repairAll() }
                            }
                        }

                        if formula.isInstalled {
                            Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {
                                Task { await self.confirmUninstall(formula) }
                            }
                        } else {
                            Button("phpman.buttons.install".localizedForSwiftUI) {
                                Task { await self.install(formula) }
                            }
                        }
                    }
                    .listRowBackground(index % 2 == 0
                                       ? Color.gray.opacity(0)
                                       : Color.gray.opacity(0.08)
                    )
                    .padding(.vertical, 10)
                }
            }
        }.frame(width: 600, height: 600)
    }

    public func runCommand(_ command: InstallAndUpgradeCommand) async {
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
        await self.runCommand(InstallAndUpgradeCommand(
            title: "phpman.operations.repairing".localized,
            upgrading: [],
            installing: []
        ))
    }

    public func upgradeAll(_ formulae: [BrewFormula]) async {
        await self.runCommand(InstallAndUpgradeCommand(
            title: "phpman.operations.updating".localized,
            upgrading: formulae,
            installing: []
        ))
    }

    public func install(_ formula: BrewFormula) async {
        await self.runCommand(InstallAndUpgradeCommand(
            title: "phpman.operations.installing".localized(formula.displayName),
            upgrading: [],
            installing: [formula]
        ))
    }

    public func confirmUninstall(_ formula: BrewFormula) async {
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

    public func uninstall(_ formula: BrewFormula) async {
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
        PhpEnvironments.shared.isBusy = busy
        if busy {
            Task { @MainActor in
                MainMenu.shared.setBusyImage()
                MainMenu.shared.rebuild()
                self.status.busy = busy
            }
        } else {
            Task { @MainActor in
                MainMenu.shared.updatePhpVersionInStatusBar()
                self.status.busy = busy
            }
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
// swiftlint:enable type_body_length

struct PhpVersionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        PhpVersionManagerView(
            formulae: Brew.shared.formulae,
            handler: FakeBrewFormulaeHandler()
        ).frame(width: 600, height: 600)
    }
}
