//
//  ByteLimitView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/07/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct PreferenceContainer<ControlView: View>: View {
    private var name: String
    private var description: String
    private var controlView: ControlView

    init(
        name: String,
        description: String,
        @ViewBuilder _ controlView: () -> ControlView
    ) {
        self.name = name
        self.description = description
        self.controlView = controlView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 50) {
                VStack(alignment: .leading) {
                    Text(self.name.localizedForSwiftUI)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .frame(minWidth: 150, maxWidth: 150, alignment: .leading)
                }

                VStack(alignment: .leading) {
                    controlView
                    Text(self.description.localizedForSwiftUI).font(.subheadline)
                }.frame(maxWidth: .infinity, alignment: .leading)
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

    func setValue(value: String) {
        return
    }

    func getValue() -> String {
        return "ok"
    }
}

struct ByteLimitView_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceContainer(name: "Something\nStupid", description: "Description") {
            ByteLimitView()
        }
    }
}
