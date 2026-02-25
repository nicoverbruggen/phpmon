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

    var body: some View {
        HStack {
            Button("startup.alert.quit".localized) {
                onQuit()
            }
            .disabled(state == .running)

            Spacer()

            switch state {
            case .idle where hasFix:
                Button("startup.fix_manually".localized) {
                    onRetry()
                }
                Button("startup.alert.fix_automatically".localized) {
                    onFix()
                }
                .buttonStyle(.custom)

            case .running:
                HStack(spacing: 10) {
                    Text("Applying. Please wait...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ProgressView()
                        .controlSize(.small)
                }

            case .completed where hasFix:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Fix applied successfully!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .idle, .completed:
                Button("startup.alert.retry".localized) {
                    onRetry()
                }
            }
        }
        .padding(20)
    }
}

#Preview("Fix available") {
    StartupAlertButtonRow(
        state: .idle, hasFix: true,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}

#Preview("Running") {
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

#Preview("No fix") {
    StartupAlertButtonRow(
        state: .completed, hasFix: false,
        onQuit: {}, onRetry: {}, onFix: {}
    )
    .frame(width: 460)
}
