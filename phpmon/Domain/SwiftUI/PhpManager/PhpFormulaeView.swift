//
//  PhpFormulaeView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class PhpFormulaeStatus: ObservableObject {
    @Published var busy: Bool
    @Published var title: String
    @Published var description: String

    init(busy: Bool, title: String, description: String) {
        self.busy = busy
        self.title = title
        self.description = description
    }
}

struct PhpFormulaeView: View {
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

            await PhpEnv.detectPhpVersions()
            await self.handler.refreshPhpVersions(loadOutdated: false)
            await self.handler.refreshPhpVersions(loadOutdated: true)
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

            Divider()

            HStack(alignment: .center, spacing: 15) {
                Button {
                    Task { // Reload warnings
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

            BlockingOverlayView(busy: self.status.busy, title: self.status.title, text: self.status.description) {
                List(Array(formulae.phpVersions.enumerated()), id: \.1.name) { (index, formula) in
                    HStack {
                        Image(systemName: formula.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(formula.iconColor)
                            .padding(.horizontal, 5)
                        VStack(alignment: .leading) {
                            Text(formula.displayName).bold()

                            if formula.isInstalled && formula.hasUpgrade {
                                Text("\(formula.installedVersion!) installed, \(formula.upgradeVersion!) available.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            } else if formula.isInstalled && formula.installedVersion != nil {
                                Text("\(formula.installedVersion!) is currently installed.").font(.system(size: 11))
                                    .foregroundColor(.gray)
                            } else {
                                Text("phpman.version.available_for_installation".localizedForSwiftUI)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if formula.isInstalled {
                            Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {
                                Task { await self.confirmUninstall(formula) }
                            }
                        } else {
                            Button("phpman.buttons.install".localizedForSwiftUI) {
                                Task { await self.install(formula) }
                            }
                        }
                        /*
                        // TODO: Remove this and add a "upgrade all" button instead?
                        if formula.hasUpgrade {
                            Button("phpman.buttons.update".localizedForSwiftUI) {
                                Task { await self.install(formula) }
                            }
                        }
                        */
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

    public func install(_ formula: BrewFormula) async {
        let command = InstallPhpVersionCommand(formula: formula.name)

        do {
            self.setBusyStatus(true)
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1

                    if progress.value == 1 {
                        self.setBusyStatus(false)
                        await self.handler.refreshPhpVersions(loadOutdated: false)
                    }
                }
            }
        } catch {
            self.setBusyStatus(false)
            self.presentErrorAlert(
                title: "phpman.failures.install.title".localized,
                description: "phpman.failures.install.desc".localized(
                    "brew install \(formula)"
                ),
                button: "generic.ok".localized
            )
        }
    }

    public func confirmUninstall(_ formula: BrewFormula) async {
        // Disallow removal of the currently active versipn
        if formula.installedVersion == PhpEnv.shared.currentInstall?.version.text {
            self.presentErrorAlert(
                title: "phpman.uninstall_prevented.title".localized,
                description: "phpman.uninstall_prevented.desc".localized,
                button: "generic.ok".localized
            )
            return
        }

        Alert.confirm(
            onWindow: App.shared.versionManagerWindowController!.window!,
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
                    "brew uninstall \(formula) --force"
                ),
                button: "generic.ok".localized
            )
        }
    }

    public func setBusyStatus(_ busy: Bool) {
        PhpEnv.shared.isBusy = busy
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
            onWindow: App.shared.versionManagerWindowController!.window!,
            messageText: title,
            informativeText: description,
            buttonTitle: button,
            secondButtonTitle: "",
            style: style,
            onFirstButtonPressed: {}
        )
    }
}

struct PhpFormulaeView_Previews: PreviewProvider {
    static var previews: some View {
        PhpFormulaeView(
            formulae: Brew.shared.formulae,
            handler: FakeBrewFormulaeHandler()
        ).frame(width: 600, height: 600)
    }
}

class FakeBrewFormulaeHandler: HandlesBrewFormulae {
    public func loadPhpVersions(loadOutdated: Bool) async -> [BrewFormula] {
        return [
            BrewFormula(
                name: "php",
                displayName: "PHP 8.2",
                installedVersion: "8.2.3",
                upgradeVersion: "8.2.4"
            ),
            BrewFormula(
                name: "php@8.1",
                displayName: "PHP 8.1",
                installedVersion: "8.1.17",
                upgradeVersion: nil
            ),
            BrewFormula(
                name: "php@8.0",
                displayName: "PHP 8.0",
                installedVersion: nil,
                upgradeVersion: nil
            ),
            BrewFormula(
                name: "php@7.4",
                displayName: "PHP 7.4",
                installedVersion: nil,
                upgradeVersion: nil
            ),
            BrewFormula(
                name: "php@7.3",
                displayName: "PHP 7.3",
                installedVersion: nil,
                upgradeVersion: nil
            ),
            BrewFormula(
                name: "php@7.2",
                displayName: "PHP 7.2",
                installedVersion: nil,
                upgradeVersion: nil
            ),
            BrewFormula(
                name: "php@7.1",
                displayName: "PHP 7.1",
                installedVersion: nil,
                upgradeVersion: nil
            )
        ]
    }
}

extension BrewFormula {
    var icon: String {
        if self.hasUpgrade {
            return "arrow.up.square.fill"
        } else if self.isInstalled {
            return "checkmark.square.fill"
        }
        return "square.dashed"
    }

    var iconColor: Color {
        if self.hasUpgrade {
            return Color("StatusColorBlue")
        } else if self.isInstalled {
            return Color("StatusColorGreen")
        }
        return Color.gray.opacity(0.3)
    }
}
