//
//  WarningView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/07/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningView: View {
    @State var title: String
    @State var description: String
    @State var documentationUrl: String?

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.orange)
                    .padding()
                VStack(alignment: .leading, spacing: 5) {
                    Text(title.localizedForSwiftUI)
                        .fontWeight(.bold)
                    Text(description.localizedForSwiftUI)
                        .font(.system(size: 12))
                }
                if documentationUrl != nil {
                    Button("Learn More") {
                        NSWorkspace.shared.open(URL(string: documentationUrl!)!)
                    }.padding()
                }
            }.padding(5)
        }
    }
}

struct WarningView_Previews: PreviewProvider {
    static var previews: some View {
        WarningView(
            title: "warnings.helper_permissions_title",
            description: "warnings.helper_permissions.description",
            documentationUrl: "https://nicoverbruggen.be"
        )
        WarningView(
            title: "warnings.helper_permissions_title",
            description: "warnings.helper_permissions.description"
        )
        .preferredColorScheme(.dark)
    }
}
