//
//  PhpManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct PhpInstallable {
    var name: String
    var installed: String?
    var latest: String
    var actions: [PhpInstallAction]

    var icon: String {
        if actions.contains(.upgrade) {
            return "arrow.up.square.fill"
        }
        if actions.contains(.remove) || installed != nil {
            return "checkmark.square.fill"
        }
        return "square.dashed"
    }

    var iconColor: Color {
        if actions.contains(.upgrade) {
            return .blue
        } else if actions.contains(.remove) || installed != nil {
            return .green
        }
        return Color.gray.opacity(0.3)
    }
}

struct ContentView: View {
    @State var phpVersions: [PhpInstallable]

    var body: some View {
        List(Array(phpVersions.enumerated()), id: \.1.name) { (index, version) in
            HStack {
                Image(systemName: version.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(version.iconColor)
                    .padding(.horizontal, 5)
                VStack(alignment: .leading) {
                    Text(version.name).bold()

                    if version.actions.contains(.upgrade) {
                        Text("\(version.installed!) installed, \(version.latest) available.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    } else if version.installed != nil {
                        Text("Latest version is currently installed.").font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    if version.actions.contains(.install) {
                        Text("This version can be installed.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if version.actions.contains(.install) {
                    Button("Install") {
                        // handle install action here
                    }
                }
                if version.actions.contains(.upgrade) {
                    Button("Upgrade") {
                        // handle uninstall action here
                    }
                }
                if version.actions.contains(.remove) {
                    Button("Uninstall") {
                        // handle uninstall action here
                    }
                }
                if version.actions.isEmpty {
                    Button("Unavailable") {
                        // handle uninstall action here
                    }.disabled(true)
                }

            }
            .listRowBackground(index % 2 == 0
                ? Color.gray.opacity(0)
                : Color.gray.opacity(0.08)
            )
            .padding(.vertical, 10)
        }
        .frame(width: 500, height: 500)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(phpVersions: [
            PhpInstallable(name: "PHP 8.2", installed: "8.2.3", latest: "8.2.3", actions: []),
            PhpInstallable(name: "PHP 8.1", installed: "8.1.0", latest: "8.1.5", actions: [.upgrade, .remove]),
            PhpInstallable(name: "PHP 8.0", installed: "8.0.14", latest: "8.0.14", actions: [.remove]),
            PhpInstallable(name: "PHP 7.4", installed: nil, latest: "", actions: [.install]),
            PhpInstallable(name: "PHP 7.3", installed: nil, latest: "", actions: [.install]),
            PhpInstallable(name: "PHP 7.2", installed: nil, latest: "", actions: [.install]),
            PhpInstallable(name: "PHP 7.1", installed: nil, latest: "", actions: [.install])
        ]).frame(width: 600, height: 500)
    }
}
