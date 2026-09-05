//
//  ByteLimitView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/07/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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
                TextField("", text: Binding(
                    get: { numberText },
                    set: { newText in
                        numberText = newText
                        save(after: 1.5)
                    }
                ))
                Picker("Limit Name", selection: Binding(
                    get: { unit },
                    set: { newUnit in
                        unit = newUnit
                        save(after: 0)
                    }
                )) {
                    ForEach(BytePhpPreference.UnitOption.allCases, id: \.self) {
                        Text($0.displayValue)
                    }
                }
                .frame(maxWidth: 100)
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }

        Toggle(isOn: Binding(
            get: { unlimited },
            set: { newValue in
                unlimited = newValue
                numberText = newValue ? "-1" : "512"
                unit = .megabyte
                save(after: 0.8)
            }
        )) {
            Text("confman.byte_limit.unlimited".localizedForSwiftUI)
        }
    }

    private func save(after delay: TimeInterval) {
        timer?.invalidate()
        // Save the displayed value and unit together. A newer edit replaces any pending write.
        let value = unlimited ? -1 : Int(numberText) ?? 256
        let unit = self.unit
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak preference] _ in
            // Scheduled on the main run loop.
            MainActor.assumeIsolated {
                guard let preference else { return }
                if preference.unit != unit { preference.unit = unit }
                if preference.value != value { preference.value = value }
            }
        }
    }
}

#Preview("Byte Limit View") {
    PreferenceContainer(
        name: "Max Size",
        description:
            "Here's an extensive description that is obviously way too long but it should wrap." +
        "The point of the wrapping text is that is allows us to see what's going on with the layout here."
    ) {
        ByteLimitView(preference: BytePhpPreference(App.shared.container, key: "max_memory"))
    }.frame(width: 600, height: 200)
}

#Preview("Config Manager") {
    ConfigManagerView()
        .frame(width: 600, height: .infinity)
}
