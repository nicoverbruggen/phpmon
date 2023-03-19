//
//  PhpFormulaeManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct PhpFormulaeManager: View {
    @State var formulae: [BrewFormula]
    @State var busy: Bool = true
    @State var title: String = "Doing a thing"
    @State var description: String = "Preparing..."

    var body: some View {
        BlockingOverlayView(busy: busy, title: title, text: description) {
            List(Array(formulae.enumerated()), id: \.1.name) { (index, formula) in
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
                            // handle uninstall action here
                        }
                    } else {
                        Button("Install") {
                            // handle install action here
                        }
                    }
                    if formula.hasUpgrade {
                        Button("Update") {
                            // handle uninstall action here
                        }
                    }
                }
                .listRowBackground(index % 2 == 0
                                   ? Color.gray.opacity(0)
                                   : Color.gray.opacity(0.08)
                )
                .padding(.vertical, 10)
            }
        }.frame(width: 500, height: 500)
    }
}

struct PhpFormulaeManager_Previews: PreviewProvider {
    static var previews: some View {
        PhpFormulaeManager(formulae: [
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
        ]).frame(width: 600, height: 500)
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
