//
//  WarningListView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningListView: View {
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Image(systemName: "stethoscope.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.red)
                    .padding(12)
                VStack(alignment: .trailing, spacing: 5) {
                    Text("warnings.description".localizedForSwiftUI)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("warnings.disclaimer".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)

            List {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(WarningManager.shared.warnings) { warning in
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
