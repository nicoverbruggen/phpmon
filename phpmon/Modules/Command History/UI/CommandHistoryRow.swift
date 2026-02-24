//
//  CommandHistoryRow.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct CommandHistoryRow: View {
    let command: LoggedCommand
    let now: Date
    let isEvenRow: Bool
    let onAppear: () -> Void
    let onDisappear: () -> Void
    let onCompleted: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if command.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 16)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 16)
                    }
                    Text(command.command)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(2)
                }

                Text(command.durationText(at: now))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .onChange(of: command.isCompleted) { isCompleted in
            guard isCompleted else { return }
            onCompleted()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(
            Color(nsColor: NSColor.alternatingContentBackgroundColors[isEvenRow ? 0 : 1])
        )
    }
}
