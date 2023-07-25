//
//  ConfigManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/07/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct ConfigManagerView: View {
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: "square.and.pencil.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.blue)
                    .padding(12)
                VStack(alignment: .leading, spacing: 5) {
                    Text("confman.title".localizedForSwiftUI)
                        .bold()
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("confman.description".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                        .scaledToFit()
                        .lineLimit(4)
                }
            }
            .padding(10)

            Divider()

            VStack(spacing: 5) {
                PreferenceContainer()
                // PreferenceContainer()
                // PreferenceContainer()
                Divider()
                HStack() {
                    Button("Close", action: {

                    })
                    Spacer()
                    Button("Restart PHP-FPM", action: {

                    })
                }
                .padding(10)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
        }
    }
}

struct ConfigManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigManagerView()
            // .frame(width: 600, height: 480)
            .previewDisplayName("Config Manager")
    }
}
