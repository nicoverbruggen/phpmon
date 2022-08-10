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
        List {
            VStack(alignment: .leading) {
                ForEach(WarningManager.shared.warnings) { warning in
                    WarningView(
                        title: warning.titleText,
                        description: warning.descriptionText,
                        documentationUrl: warning.url
                    )
                    Divider()
                }
            }

        }
        .navigationTitle("Warnings")
        .listStyle(.automatic)
    }
}

struct WarningListView_Previews: PreviewProvider {
    static var previews: some View {
        WarningListView()
    }
}
