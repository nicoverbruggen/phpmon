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
    @ObservedObject var status: BusyStatus
    var handler: HandlesBrewPhpFormulae

    init(
        formulae: BrewFormulaeObservable,
        handler: HandlesBrewPhpFormulae
    ) {
        self.formulae = formulae
        self.handler = handler

        self.status = BusyStatus(
            busy: true,
            title: "phpman.busy.title".localized,
            description: "phpman.busy.description.outdated".localized
        )

        Task { [self] in
            if handler is FakeBrewFormulaeHandler {
                await self.fakeInitialLoad()
            } else {
                await self.initialLoad()
            }
        }
    }

    private func fakeInitialLoad() async {
        await self.handler.refreshPhpVersions(loadOutdated: false)
        self.status.busy = false
    }

    private func initialLoad() async {
        guard let version = Brew.shared.version else {
            return
        }

        await delay(seconds: 1)

        // PHP formulae may not be installable with older Homebrew version
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

        // PHP formulae may be out of date past the cutoff date
        if Date.fromString(Constants.PhpFormulaeCutoffDate)! < Date.now {
            self.presentErrorAlert(
                title: "phpman.warnings.outdated.title".localized,
                description: "phpman.warnings.outdated.desc".localized(version.text),
                button: "generic.ok".localized,
                style: .warning
            )
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
            header.padding(10)

            Divider()

            if self.hasUpdates {
                hasUpdatesView
            } else {
                noUpdatesView
            }

            BlockingOverlayView(
                busy: self.status.busy,
                title: self.status.title,
                text: self.status.description
            ) {
                if #available(macOS 13, *) {
                    List(Array(formulae.phpVersions.enumerated()), id: \.1.name) { (index, formula) in
                        listContent(for: formula)
                            .listRowBackground(
                                index % 2 == 0
                                ? Color.gray.opacity(0)
                                : Color.gray.opacity(0.08)
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .listRowSeparator(.hidden)
                    }
                    .edgesIgnoringSafeArea(.top)
                    .listStyle(PlainListStyle())
                } else {
                    List(Array(formulae.phpVersions.enumerated()), id: \.1.name) { (index, formula) in
                        listContent(for: formula)
                            .listRowBackground(
                                index % 2 == 0
                                ? Color.gray.opacity(0)
                                : Color.gray.opacity(0.08)
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                    }
                    .edgesIgnoringSafeArea(.top)
                    .listStyle(PlainListStyle())
                }
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }

    // MARK: View Variables

    private var header: some View {
        HStack(alignment: .center, spacing: 15) {
            Image.init(.php)
                .resizable()
                .frame(width: 50, height: 50)
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
    }

    private var hasUpdatesView: some View {
        Group {
            HStack(alignment: .center, spacing: 15) {
                Text("phpman.has_updates.description".localizedForSwiftUI)
                    .font(.system(size: 11))

                Button(action: {
                    Task { await self.upgradeAll(self.formulae.upgradeable) }
                }, label: {
                    Label("phpman.has_updates.button".localizedForSwiftUI,
                          systemImage: "arrowshape.up.circle.fill")
                })
                .buttonStyle(.custom)
                .focusable(false)
                .disabled(self.status.busy)
            }
            .padding(10)
        }
        .background(.statusColorYellowTranslucent)
        .cornerRadius(5)
    }

    private var noUpdatesView: some View {
        HStack(alignment: .center, spacing: 15) {
            Button {
                Task { await self.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .buttonStyle(.automatic)
                    .controlSize(.large)
            }
            .accessibilityIdentifier("RefreshButton")
            .focusable(false)
            .disabled(self.status.busy)

            Text("phpman.refresh.button.description".localizedForSwiftUI)
                .foregroundColor(.gray)
                .font(.system(size: 11))
        }
        .padding(10)
    }

    private var prereleaseBadge: some View {
        Text("phpman.version.prerelease".localized.uppercased())
            .font(.system(size: 9))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Color.statusColorBlue)
            .foregroundColor(Color.white)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: true)
    }

    // MARK: View Builders

    private func listContent(for formula: BrewPhpFormula) -> some View {
        HStack(alignment: .center, spacing: 7.0) {
            formulaIcon(for: formula)
            formulaDescription(for: formula)
            formulaButtons(for: formula)
        }
    }

    private func formulaButtons(for formula: BrewPhpFormula) -> some View {
        HStack {
            if !formula.healthy {
                Button("phpman.buttons.repair".localizedForSwiftUI, role: .destructive) {
                    Task { await self.repairAll() }
                }
            }

            if formula.hasUpgradedFormulaAlias {
                HelpButton(frameSize: 18, textSize: 14, shadowOpacity: 1, shadowRadius: 2, action: {
                    NSWorkspace.shared.open(Constants.Urls.WikiPhpUpgrade)
                })
            } else if formula.isInstalled {
                Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {
                    Task { await self.confirmUninstall(formula) }
                }
            } else {
                Button("phpman.buttons.install".localizedForSwiftUI) {
                    Task { await self.install(formula) }
                }.disabled(formula.hasUpgradedFormulaAlias || !formula.hasFormulaFile)
            }
        }
    }

    private func formulaDescription(for formula: BrewPhpFormula) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(formula.displayName).bold()

                if formula.prerelease {
                    prereleaseBadge
                }
            }

            if formula.hasUpgradedFormulaAlias {
                Text("phpman.version.automatic_upgrade".localized(formula.shortVersion!))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            } else if formula.isInstalled && formula.hasUpgrade {
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
            } else if !formula.hasFormulaFile {
                unavailableFormula()
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
    }

    private func formulaIcon(for formula: BrewPhpFormula) -> some View {
        Image(systemName: formula.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .foregroundColor(formula.iconColor)
            .padding(.horizontal, 5)
    }

    private func unavailableFormula() -> some View {
        HStack(spacing: 5) {
            Text("phpman.version.unavailable".localizedForSwiftUI)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            HelpButton(action: {
                NSWorkspace.shared.open(Constants.Urls.WikiPhpUnavailable)
            })
        }
    }
}
// swiftlint:enable type_body_length

#Preview {
    PhpVersionManagerView(
        formulae: Brew.shared.formulae,
        handler: FakeBrewFormulaeHandler()
    ).frame(width: 600, height: 600)
}
