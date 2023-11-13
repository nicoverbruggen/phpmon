//
//  PhpExtensionManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

// Temp model for UI purposes
struct BrewPhpExtension {
    let name: String
    let isInstalled: Bool
}

struct PhpExtensionManagerView: View {
    init() {
        let available = BrewTapFormulae
            .from(tap: "shivammathur/homebrew-extensions")["8.2"]!.sorted()

        print(available)

        let extensions = available.map({ name in
            return BrewPhpExtension(name: name, isInstalled: false)
        })

        self.extensions = extensions
    }

    @State var searchText: String = ""
    @State var extensions: [BrewPhpExtension]

    var body: some View {
        VStack {
            header.padding(20)

            List(Array(extensions.enumerated()), id: \.1.name) { (index, pExtension) in
                listContent(for: pExtension)
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
