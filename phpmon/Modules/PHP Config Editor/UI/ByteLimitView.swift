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
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(self.name))
                        .bold()
                        .multilineTextAlignment(.leading)
                        .frame(minWidth: 150, maxWidth: 150, alignment: .leading)
                }

                VStack(alignment: .leading) {
                    controlView

                    Text(self.description.localizedForSwiftUI)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: 150, alignment: .topLeading)
            }
        }
        .padding(5)
    }
}

struct ByteLimitView: View {
    @State private var unit: BytePhpPreference.UnitOption
    @State private var numberText: String
    @State private var unlimited: Bool

    private var preference: BytePhpPreference

    init(preference: BytePhpPreference) {
        self.preference = preference
        self.numberText = String(preference.value)
        self.unit = preference.unit
        self.unlimited = (preference.value == -1)
    }

    var body: some View {
        if !unlimited {
            HStack {
                TextField("", text: $numberText)
                    .onChange(of: numberText) { newText in
                        self.preference.value = Int(newText) ?? 256
                        print(self.preference.internalValue)
                    }
                Picker("Limit Name", selection: $unit) {
                    ForEach(BytePhpPreference.UnitOption.allCases, id: \.self) {
                        Text($0.displayValue)
                    }
                }
                .frame(maxWidth: 100)
                .labelsHidden()
                .pickerStyle(.menu)
                .onChange(of: unit) { newValue in
                    self.preference.unit = newValue
                }
            }
        }

        Toggle(isOn: $unlimited) {
            Label("Allow unlimited usage", systemImage: "heart").labelStyle(.titleOnly)
        }
    }
}

struct ByteLimitView_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceContainer(name: "Max Size", description: "Some maximum size") {
            ByteLimitView(preference: BytePhpPreference(key: "max_memory"))
        }

        ConfigManagerView()
            .frame(width: 600, height: .infinity)
            .previewDisplayName("Config Manager")
    }
}
