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

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 25, height: 25)
                .padding()
                .foregroundColor(Color.orange)
            VStack(alignment: .leading, spacing: 5) {
                Text(title.localizedForSwiftUI)
                    .fontWeight(.bold)
                Text(description.localizedForSwiftUI)
                    .font(.body)

            }
        }.padding()
    }
}

struct WarningView_Previews: PreviewProvider {
    static var previews: some View {
        WarningView(
            title: "warnings.helper_permissions_title",
            description: "warnings.helper_permissions.description"
        )
        WarningView(
            title: "warnings.helper_permissions_title",
            description: "warnings.helper_permissions.description"
        )
        .preferredColorScheme(.dark)
    }
}
