//
//  PhpExtensionManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct PhpExtensionManagerView: View {
    @ObservedObject var manager: BrewExtensionsObservable
    @ObservedObject var status: BusyStatus
    @State var searchText: String

    init() {
        self.searchText = ""
        self.status = BusyStatus.busy()
        let version = PhpEnvironments.shared.currentInstall!.version.short
        self.manager = BrewExtensionsObservable(phpVersion: version)
        self.status.busy = false
    }

    var filteredExtensions: [BrewPhpExtension] {
        guard !searchText.isEmpty else {
            return manager.extensions
        }
        return manager.extensions.filter { $0.name.contains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(20)

            if PhpEnvironments.shared.availablePhpVersions.count <= 4 {
                Picker("Show extensions for: ",
                       selection: $manager.phpVersion) {
                    ForEach(PhpEnvironments.shared.availablePhpVersions, id: \.self) {
                        Text("PHP \($0)")
                            .tag($0)
                            .font(.system(size: 12))
                    }
                }
               .pickerStyle(SegmentedPickerStyle()).padding(15)
               .font(.system(size: 12))
            } else {
                Picker("Show extensions for: ",
                       selection: $manager.phpVersion) {
                    ForEach(PhpEnvironments.shared.availablePhpVersions, id: \.self) {
                        Text("PHP \($0)")
                            .tag($0)
                            .font(.system(size: 12))
                    }
                }
               .pickerStyle(MenuPickerStyle()).padding(15)
               .font(.system(size: 12))
            }

            VStack {
                Text("Currently showing \(manager.extensions.count) extensions for **PHP \(manager.phpVersion)**.")
                    .padding(10)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
            .background(Color.blue.opacity(0.3))
            .padding(.bottom, 0)

            BlockingOverlayView(
                busy: self.status.busy,
                title: self.status.title,
                text: self.status.description
            ) {
                List(Array(self.filteredExtensions.enumerated()), id: \.1.name) { (_, ext) in
                    listContent(for: ext)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                }
                .edgesIgnoringSafeArea(.top)
                .listStyle(PlainListStyle())
                .searchable(text: $searchText)
            }
        }
        .frame(width: 600, height: 600)
    }

    // MARK: View Variables

    private var header: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(systemName: "puzzlepiece.extension.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(Color.blue)
                .padding(12)
            VStack(alignment: .leading, spacing: 5) {
                Text("phpextman.description".localizedForSwiftUI)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("phpextman.disclaimer".localizedForSwiftUI)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func listContent(for ext: BrewPhpExtension) -> some View {
        HStack(alignment: .center, spacing: 7.0) {
            VStack(alignment: .center, spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: ext.isInstalled || ext.hasAlternativeInstall
                              ? "puzzlepiece.extension.fill"
                              : "puzzlepiece.extension")
                            .resizable()
                            .frame(width: 24, height: 20)
                            .foregroundColor(ext.hasAlternativeInstall ? Color.gray : Color.blue)
                    }.frame(width: 36, height: 24)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(ext.name).bold()
                        }

                        if !ext.dependencies.isEmpty {
                            HStack(spacing: 3) {
                                Text("Depends on:")
                                    .font(.system(size: 10))
                                ForEach(ext.dependencies, id: \.self) {
                                    Text($0)
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.gray)
                                        .foregroundColor(Color.white)
                                        .clipShape(Capsule())
                                        .fixedSize(horizontal: true, vertical: true)
                                }
                            }
                        }

                        if ext.isInstalled {
                            Text("This extension is installed and can be managed by PHP Monitor.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else {
                            if ext.hasAlternativeInstall {
                                Text("This extension is already installed via another source, and cannot be managed.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.orange)
                            } else {
                                Text("This extension can be installed.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if ext.isInstalled {
                    Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {
                        self.confirmUninstall(ext)
                    }
                } else {
                    Button("phpman.buttons.install".localizedForSwiftUI) {
                        self.install(ext)
                    }.disabled(ext.hasAlternativeInstall)
                }
            }
        }
    }
}

#Preview {
    PhpExtensionManagerView()
        .frame(width: 600, height: 600)
}
