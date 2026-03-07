//
//  CommandHistoryRow.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import SwiftUI

struct CommandHistoryRow: View {
    let command: LoggedCommand
    let isEvenRow: Bool
    @Binding var visibleCommandIds: Set<UUID>

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

                if command.isCompleted {
                    Text(command.durationText(at: Date()))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    TimelineView(.periodic(from: .now, by: 0.08)) { context in
                        Text(command.durationText(at: context.date))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .onAppear {
            // Track only visible, active commands to avoid unnecessary ticking
            guard !command.isCompleted else { return }
            visibleCommandIds.insert(command.id)
        }
        .onDisappear {
            // Remove from visible set when the row scrolls out
            visibleCommandIds.remove(command.id)
        }
        .onChange(of: command.isCompleted) { isCompleted in
            guard isCompleted else { return }
            // Stop ticking for this row once the command completes
            visibleCommandIds.remove(command.id)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(
            Color(nsColor: NSColor.alternatingContentBackgroundColors[isEvenRow ? 0 : 1])
        )
    }
}
