//
//  PhpExtensionManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class BrewExtensionsObservable: ObservableObject {
    @Published var extensions: [BrewPhpExtension] = [] {
        didSet {
            print(self.extensions)
        }
    }

    public func loadExtensionData(for version: String) {
        let tapFormulae = BrewTapFormulae.from(tap: "shivammathur/homebrew-extensions")
        if let filteredTapFormulae = tapFormulae[version] {
            self.extensions = filteredTapFormulae.sorted().map({ name in
                return BrewPhpExtension(name: name, isInstalled: false)
            })
        }
    }
}

// Temp model for UI purposes
struct BrewPhpExtension {
    let name: String
    let isInstalled: Bool
}

struct PhpExtensionManagerView: View {
    init() {
        self.searchText = ""
        self.phpVersion = PhpEnvironments.shared.currentInstall!.version.short
        self.manager.loadExtensionData(for: self.phpVersion)
    }

    @ObservedObject var manager = BrewExtensionsObservable()
    @State var searchText: String
    @State var phpVersion: String {
        didSet {
            self.manager.loadExtensionData(for: self.phpVersion)
            print(self.manager.extensions)
        }
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

            List(Array(self.filteredExtensions.enumerated()), id: \.1.name) { (_, pExtension) in
                listContent(for: pExtension)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
            }
            .edgesIgnoringSafeArea(.top)
            .listStyle(PlainListStyle())
            .searchable(text: $searchText)
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
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "puzzlepiece.extension")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundColor(Color.blue)
                    Text(bExtension.name).bold()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if bExtension.isInstalled {
                    Button("phpman.buttons.uninstall".localizedForSwiftUI, role: .destructive) {

                    }
                } else {
                    Button("phpman.buttons.install".localizedForSwiftUI) {

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
