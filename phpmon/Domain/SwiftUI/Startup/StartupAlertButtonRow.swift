//
//  StartupAlertButtonRow.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupAlertButtonRow: View {
    let state: StartupAlertViewModel.State
    let hasFix: Bool
    let onQuit: () -> Void
    let onRetry: () -> Void
    let onFix: () -> Void

    private enum FocusedButton {
        case fix, retry, quit
    }

    @FocusState private var focusedButton: FocusedButton?

    var body: some View {
        HStack {
            switch state {
            case .idle:
                Button("startup.alert.quit".localized) {
                    onQuit()
                }
                .focused($focusedButton, equals: .quit)
                .disabled(state == .running)

                Spacer()

                Button("startup.alert.fix_manually".localized) {
                    onRetry()
                }
                .focused($focusedButton, equals: .retry)

                if hasFix {
                    Button("startup.alert.fix_automatically".localized) {
                        onFix()
                    }
                    .focused($focusedButton, equals: .fix)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.custom)
                }

            case .running:
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Applying. Please wait...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .completed:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Fix applied successfully! Continuing...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .onAppear {
            focusedButton = hasFix ? .fix : .retry
        }
    }
}

// MARK: - Previews

#Preview("Fix Available") {
    StartupAlertButtonRow(
        state: .idle, hasFix: true,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}

#Preview("No Fix Available") {
    StartupAlertButtonRow(
        state: .idle, hasFix: false,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}

#Preview("Fix Being Applied") {
    StartupAlertButtonRow(
        state: .running, hasFix: true,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}

#Preview("Fix succeeded") {
    StartupAlertButtonRow(
        state: .completed, hasFix: true,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}
