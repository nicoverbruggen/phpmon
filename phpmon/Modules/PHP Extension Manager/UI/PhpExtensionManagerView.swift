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
    @ObservedObject var manager = BrewExtensionsObservable()
    @ObservedObject var status: BusyStatus
    @State var searchText: String
    @State var phpVersion: String {
        didSet {
            self.manager.loadExtensionData(for: self.phpVersion)
        }
    }

    init() {
        self.searchText = ""
        self.status = BusyStatus.busy()
        self.phpVersion = PhpEnvironments.shared.currentInstall!.version.short
        self.manager.loadExtensionData(for: self.phpVersion)
        self.status.busy = false
        #warning("PHP extension manager does not react to PHP version changes!")
    }

    var filteredExtensions: [BrewPhpExtension] {
        guard !searchText.isEmpty else {
            return manager.extensions
        }
        return manager.extensions.filter { $0.name.contains(searchText) }
    }

    var body: some View {
        VStack {
            header.padding(20)

            BlockingOverlayView(
                busy: self.status.busy,
                title: self.status.title,
                text: self.status.description
            ) {
                List(Array(self.filteredExtensions.enumerated()), id: \.1.name) { (_, pExtension) in
                    listContent(for: pExtension)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                }
                .edgesIgnoringSafeArea(.top)
                .listStyle(PlainListStyle())
                .searchable(text: $searchText)
            }
        }.frame(width: 600, height: 600)
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

    private func listContent(for bExtension: BrewPhpExtension) -> some View {
        HStack(alignment: .center, spacing: 7.0) {
            VStack(alignment: .center, spacing: 0) {
                HStack {
                    Image(systemName: bExtension.isInstalled 
                          ? "puzzlepiece.extension.fill"
                          : "puzzlepiece.extension")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.blue)
                    Text(bExtension.name).bold()
                    Text("for PHP \(bExtension.phpVersion)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if bExtension.isInstalled {
                    Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {
                        Task { await self.runCommand(
                            RemovePhpExtensionCommand(remove: bExtension)
                        ) }
                    }
                } else {
                    Button("phpman.buttons.install".localizedForSwiftUI) {
                        Task { await self.runCommand(
                            InstallPhpExtensionCommand(install: [bExtension])
                        ) }
                    }
                }
            }
        }
    }
}

#Preview {
    PhpExtensionManagerView()
        .frame(width: 600, height: 600)
}
