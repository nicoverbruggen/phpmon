//
//  PhpDoctorView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct PhpDoctorView: View {
    @ObservedObject var warningManager: WarningManager

    init(empty: Bool = false, fake: Bool = false, manager: WarningManager? = nil) {
        if manager == nil {
            // Use the singleton by default
            warningManager = WarningManager.shared
        } else {
            // Use a provided instance (for e.g. preview purposes)
            warningManager = manager!
        }

        if fake {
            warningManager.warnings = warningManager.evaluations
        }

        if empty {
            warningManager.clearWarnings()
        }
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: "stethoscope.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.red)
                    .padding(12)
                VStack(alignment: .leading, spacing: 5) {
                    Text("warnings.description".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("warnings.disclaimer".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)

            Divider()

            HStack(alignment: .center, spacing: 15) {
                Button {
                    Task { // Reload warnings
                        await self.warningManager.checkEnvironment()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .buttonStyle(.automatic)
                        .controlSize(.large)
                }
                Text("warnings.refresh.button.description".localizedForSwiftUI)
                    .foregroundColor(.gray)
                    .font(.system(size: 11))
            }
            .padding(10)

            List {
                VStack(alignment: .leading, spacing: 0) {
                    if !warningManager.hasWarnings() {
                        NoWarningsView()
                    } else {
                        ForEach(warningManager.warnings) { warning in
                            Group {
                                WarningView(
                                    title: warning.title,
                                    paragraphs: warning.paragraphs(),
                                    documentationUrl: warning.url
                                )
                                .fixedSize(horizontal: false, vertical: true)

                                Divider()
                            }.padding(5)
                        }
                    }
                }
                .frame(minHeight: 0, maxHeight: .infinity).padding(5)
            }
            .listRowInsets(EdgeInsets())
            .listStyle(.plain)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct WarningListView_Previews: PreviewProvider {
    static var previews: some View {
        PhpDoctorView(empty: true, fake: true, manager: WarningManager())
            .frame(width: 600, height: 480)
            .previewDisplayName("Empty List")

        PhpDoctorView(empty: false, fake: true, manager: WarningManager())
            .frame(width: 600, height: 480)
            .previewDisplayName("List With All Warnings")
    }
}
