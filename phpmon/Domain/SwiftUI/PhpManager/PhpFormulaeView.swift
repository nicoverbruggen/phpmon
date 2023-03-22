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
            title: "Checking for updates!",
            description: "Checking if any PHP version is outdated..."
        )

        Task { [self] in
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
                            self.status.title = "Checking for updates!"
                            self.status.description = "Checking if any PHP version is outdated..."
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
                                Text("Latest version is currently installed.").font(.system(size: 11))
                                    .foregroundColor(.gray)
                            } else {
                                Text("This version can be installed.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if formula.isInstalled {
                            Button("Uninstall") {
                                Task { await self.uninstall(formula) }
                            }
                        } else {
                            Button("Install") {
                                Task { await self.install(formula) }
                            }
                        }
                        if formula.hasUpgrade {
                            Button("Update") {
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

    public func install(_ formula: BrewFormula) async {
        let command = InstallPhpVersionCommand(formula: formula.name)

        do {
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1

                    if progress.value == 1 {
                        await self.handler.refreshPhpVersions(loadOutdated: false)
                    }
                }
            }
        } catch {
            Task { @MainActor in
                self.status.busy = false
            }
            self.presentErrorAlert(
                title: "phpman.failures.install.title".localized,
                description: "phpman.failures.install.desc".localized(
                    "brew install \(formula)"
                ),
                button: "generic.ok"
            )
        }
    }

    public func uninstall(_ formula: BrewFormula) async {
        let command = RemovePhpVersionCommand(formula: formula.name)

        do {
            try await command.execute { progress in
                Task { @MainActor in
                    self.status.title = progress.title
                    self.status.description = progress.description
                    self.status.busy = progress.value != 1

                    if progress.value == 1 {
                        await self.handler.refreshPhpVersions(loadOutdated: false)
                    }
                }
            }
        } catch {
            Task { @MainActor in
                self.status.busy = false
            }
            self.presentErrorAlert(
                title: "phpman.failures.uninstall.title".localized,
                description: "phpman.failures.uninstall.desc".localized(
                    "brew uninstall \(formula) --force"
                ),
                button: "generic.ok"
            )
        }
    }

    public func presentErrorAlert(title: String, description: String, button: String) {
        Alert.confirm(
            onWindow: App.shared.versionManagerWindowController!.window!,
            messageText: title,
            informativeText: description,
            buttonTitle: button,
            secondButtonTitle: "",
            style: .critical,
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
            return .blue
        } else if self.isInstalled {
            return .green
        }
        return Color.gray.opacity(0.3)
    }
}
