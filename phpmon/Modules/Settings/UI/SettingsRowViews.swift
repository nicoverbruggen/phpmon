//
//  SettingsRowViews.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

/** An option offered by a settings dropdown: a display label plus the stored value. */
struct PreferenceDropdownOption {
    let label: String
    let value: String
}

/**
 The layout metrics of the classic settings rows, transcribed from the old
 XIB-based row views so the SwiftUI implementation looks identical: a fixed,
 right-aligned label column, a 20pt gutter, and the control column with the
 small secondary description below each control.
 */
enum SettingsRowMetrics {
    /// The total width of a row (the old template stack view's fixed width).
    static let rowWidth: CGFloat = 550
    /// The width of the right-aligned section label column.
    static let labelWidth: CGFloat = 150
    /// The gap between the label column and the control column.
    static let columnSpacing: CGFloat = 20
    /// The trailing inset behind the control column.
    static let trailingInset: CGFloat = 20
    /// The space between a control and its description text.
    static let descriptionSpacing: CGFloat = 8
    /// The vertical padding around each row (top/bottom 5 in the XIBs).
    static let rowPadding: CGFloat = 5

    /// The resulting width of the control column.
    static var contentWidth: CGFloat {
        rowWidth - labelWidth - columnSpacing - trailingInset
    }
}

/**
 A classic settings row: right-aligned section label on the left (may be empty
 for rows that continue a section), control plus description on the right.
 */
struct SettingsRow<Control: View>: View {
    let sectionKey: String?
    let descriptionKey: String
    @ViewBuilder var control: () -> Control

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: SettingsRowMetrics.columnSpacing) {
            Text(sectionKey?.localized ?? "")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(width: SettingsRowMetrics.labelWidth, alignment: .trailing)

            VStack(alignment: .leading, spacing: SettingsRowMetrics.descriptionSpacing) {
                control()

                Text(descriptionKey.localized)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: SettingsRowMetrics.contentWidth, alignment: .leading)
            }
        }
        .padding(.vertical, SettingsRowMetrics.rowPadding)
    }
}

/**
 A checkbox bound to a boolean preference, with the explanatory text below it.

 The row re-reads the preference whenever `Events.PreferencesUpdated` fires, so
 external changes (e.g. a testable configuration or another window) stay in sync,
 mirroring the behavior of the old XIB-based checkbox rows.
 */
struct SettingsToggleRow: View {
    var sectionKey: String?
    let titleKey: String
    let descriptionKey: String
    let preference: PreferenceName
    var action: () -> Void = {}

    @State private var isOn: Bool = false

    var body: some View {
        SettingsRow(sectionKey: sectionKey, descriptionKey: descriptionKey) {
            Toggle(titleKey.localized, isOn: $isOn)
                .toggleStyle(.checkbox)
        }
        .onAppear {
            isOn = Preferences.isEnabled(preference)
        }
        .onReceive(NotificationCenter.default.publisher(for: Events.PreferencesUpdated)) { _ in
            isOn = Preferences.isEnabled(preference)
        }
        .onChange(of: isOn) { newValue in
            // Only persist actual user-driven changes; refreshes from the
            // notification above would otherwise write the same value back.
            guard newValue != Preferences.isEnabled(preference) else { return }

            Preferences.update(preference, value: newValue)
            action()
        }
    }
}

/**
 The "Start PHP Monitor at login" checkbox, backed by `SMAppService` via
 `LoginItemManager` rather than a preference key.
 */
struct SettingsLoginItemRow: View {
    let manager = LoginItemManager()

    @State private var isOn: Bool = false

    var body: some View {
        SettingsRow(sectionKey: "prefs.startup", descriptionKey: "prefs.auto_start_desc") {
            Toggle("prefs.auto_start_title".localized, isOn: $isOn)
                .toggleStyle(.checkbox)
        }
        .onAppear {
            isOn = manager.loginItemIsEnabled()
        }
        .onChange(of: isOn) { newValue in
            guard newValue != manager.loginItemIsEnabled() else { return }

            if newValue {
                manager.enableLoginItem()
            } else {
                manager.disableLoginItem()
            }

            // The system may refuse; reflect the actual outcome.
            isOn = manager.loginItemIsEnabled()
        }
    }
}

/**
 A dropdown bound to a string preference, with the explanatory text below it.
 */
struct SettingsPickerRow: View {
    var sectionKey: String?
    let descriptionKey: String
    let options: [PreferenceDropdownOption]
    var localizationPrefix: String?
    let preference: PreferenceName
    var action: () -> Void = {}

    @State private var selection: String = ""

    var body: some View {
        SettingsRow(sectionKey: sectionKey, descriptionKey: descriptionKey) {
            Picker(selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(label(for: option)).tag(option.value)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            .fixedSize()
        }
        .onAppear {
            selection = storedValue
        }
        .onReceive(NotificationCenter.default.publisher(for: Events.PreferencesUpdated)) { _ in
            selection = storedValue
        }
        .onChange(of: selection) { newValue in
            guard newValue != storedValue else { return }

            Preferences.update(preference, value: newValue)
            action()
        }
    }

    private var storedValue: String {
        return Preferences.preferences[preference] as? String ?? ""
    }

    private func label(for option: PreferenceDropdownOption) -> String {
        if let prefix = localizationPrefix {
            return "\(prefix).\(option.label)".localized
        }

        return option.label
    }
}
