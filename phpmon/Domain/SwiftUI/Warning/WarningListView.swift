//
//  WarningListView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningListView: View {
    @ObservedObject var warningManager: WarningManager

    init(empty: Bool = false) {
        if empty {
            WarningManager.shared.warnings = []
        }

        warningManager = WarningManager.shared
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
                Button("warnings.refresh.button".localizedForSwiftUI) {
                    Task { // Reload warnings
                        await WarningManager.shared.checkEnvironment()
                    }
                }
                Text("warnings.refresh.button.description".localizedForSwiftUI)
                    .foregroundColor(.gray)
                    .font(.system(size: 11))
            }
            .padding(10)

            List {
                VStack(alignment: .leading, spacing: 0) {
                    if warningManager.warnings.isEmpty {
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
        WarningListView(empty: true)
            .frame(width: 600, height: 480)
            .previewDisplayName("Empty List")

        WarningListView(empty: false)
            .frame(width: 600, height: 480)
            .previewDisplayName("List With All Warnings")
    }
}
