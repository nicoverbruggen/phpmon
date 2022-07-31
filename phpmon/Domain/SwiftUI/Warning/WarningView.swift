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
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                    .padding(.bottom, 1)
                Text(description)
                    .font(.body)
            }
        }.padding()
    }
}

struct WarningView_Previews: PreviewProvider {
    static var previews: some View {
        WarningView(
            title: "Helpers not written",
            description: "The helper files in `/usr/local/bin` could not be written because PHP Monitor does not have permission to write there."
        )
    }
}
