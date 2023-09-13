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
                        .lineLimit(nil)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(5)
    }
}

struct ByteLimitView: View {
    @State private var unit: BytePhpPreference.UnitOption
    @State private var numberText: String
    @State private var unlimited: Bool
    @State private var timer: Timer?

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
                    .onChange(of: numberText) { [weak preference] newText in
                        timer?.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                            preference?.value = Int(newText) ?? 256
                        }
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
            Text("confman.byte_limit.unlimited".localizedForSwiftUI)
        }.onChange(of: unlimited, perform: { [weak preference] unlimited in
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                preference?.value = unlimited ? -1 : 512
                preference?.unit = .megabyte
            }
        })
    }
}

struct ByteLimitView_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceContainer(
            name: "Max Size",
            description:
                "Here's an extensive description that is obviously way too long but it should wrap." +
                "The point of the wrapping text is that is allows us to see what's going on with the layout here."
        ) {
            ByteLimitView(preference: BytePhpPreference(key: "max_memory"))
        }.frame(width: 600, height: 200)

        ConfigManagerView()
            .frame(width: 600, height: .infinity)
            .previewDisplayName("Config Manager")
    }
}
