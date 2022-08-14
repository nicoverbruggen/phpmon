//
//  WarningListView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningListView: View {
    @State var warnings: [Warning] = WarningManager.shared.warnings

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
                    Task {
                        await WarningManager.shared.checkEnvironment()
                        self.warnings = WarningManager.shared.warnings
                    }
                }
                Text("warnings.refresh.button.description".localizedForSwiftUI)
                    .foregroundColor(.gray)
                    .font(.system(size: 11))
            }
            .padding(10)

            List {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(warnings) { warning in
                        Group {
                            WarningView(
                                title: warning.title,
                                paragraphs: warning.paragraphs,
                                documentationUrl: warning.url
                            )
                            .fixedSize(horizontal: false, vertical: true)

                            Divider()
                        }.padding(5)
                    }
                }.frame(minHeight: 0, maxHeight: .infinity).padding(5)
            }
            .listRowInsets(EdgeInsets())
            .listStyle(.plain)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct WarningListView_Previews: PreviewProvider {
    static var previews: some View {
        WarningListView()
            .frame(width: 600, height: 480)
    }
}
