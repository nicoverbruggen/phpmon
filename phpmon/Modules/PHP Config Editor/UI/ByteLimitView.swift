//
//  ByteLimitView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/07/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct PreferenceContainer: View {
    private var name: String = "Memory Limit"
    private var description: String = "This is the maximum memory a given PHP script may consume."
    private var controlView: some View = ByteLimitView()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 50) {
                Text(self.name).bold()
                VStack(alignment: .leading) {
                    controlView
                    Text(self.description).font(.subheadline)
                }
            }
        }
        .padding(10)
    }
}

struct ByteLimitView: View {
    @State private var selection = "256 MB"

    let colors = [
        "128 MB",
        "256 MB",
        "512 MB",
        "1 GB",
        "2 GB",
        "Unlimited",
        "Other"
    ]

    var body: some View {
        Picker("Limit Name", selection: $selection) {
            ForEach(colors, id: \.self) {
                Text($0)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
    }
}

struct ByteLimitView_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceContainer()
    }
}
