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
                WarningView(
                    title: "warnings.arm_compatibility_title",
                    description: "warnings.arm_compatibility.description",
                    documentationUrl: "https://phpmon.app/documentation/apple-silicon-transition"
                )
                Divider()
                WarningView(
                    title: "warnings.helper_permissions_title",
                    description: "warnings.helper_permissions.description"
                )
                Divider()
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
