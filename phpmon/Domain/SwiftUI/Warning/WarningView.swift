//
//  WarningView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/07/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningView: View {
    @State var title: String
    @State var paragraphs: [String]
    @State var documentationUrl: String?

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bandage.fill")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.orange)
                    .padding(.trailing, 5)
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title.localizedForSwiftUI)
                            .fontWeight(.bold)
                        ForEach(paragraphs, id: \.self) { paragraph in
                            Text(paragraph.localizedForSwiftUI)
                                .font(.system(size: 13))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(
                        minWidth: 0, maxWidth: .infinity,
                        minHeight: 0, maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    if documentationUrl != nil {
                        Button("Learn More") {
                            NSWorkspace.shared.open(URL(string: documentationUrl!)!)
                        }
                    }
                }
            }.padding(5)
        }
    }
}

struct WarningView_Previews: PreviewProvider {
    static var previews: some View {
        WarningView(
            title: "warnings.helper_permissions.title",
            paragraphs: ["warnings.helper_permissions.description"],
            documentationUrl: "https://nicoverbruggen.be"
        )
        .frame(width: 600, height: 105)

        WarningView(
            title: "warnings.helper_permissions.title",
            paragraphs: ["warnings.helper_permissions.description"],
            documentationUrl: "https://nicoverbruggen.be"
        )
        .preferredColorScheme(.dark)
        .frame(width: 600, height: 105)

        // WarningListView().frame(width: 600, height: 580)
    }
}
