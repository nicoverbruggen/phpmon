//
//  CommandHistoryView.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import AppKit
import SwiftUI

struct CommandHistoryView: View {
    // Provides access to the tracked command history
    @ObservedObject var commandTracker: CommandTracker

    // IDs for visible, active rows; used to avoid ticking when none are on-screen
    @State private var visibleCommandIds: Set<UUID> = []

    init(commandTracker: CommandTracker) {
        self.commandTracker = commandTracker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollViewReader { proxy in
                List {
                    ForEach(commandTracker.commands.indices, id: \.self) { index in
                        let command = commandTracker.commands[index]
                        let isEvenRow = index.isMultiple(of: 2)
                        CommandHistoryRow(
                            command: command,
                            isEvenRow: isEvenRow,
                            visibleCommandIds: $visibleCommandIds
                        )
                        .id(command.id)
                    }
                }
                .listStyle(.plain)
                .onChange(of: commandTracker.commands.count) { _ in
                    // Scroll to the bottom as new commands come in
                    if let last = commandTracker.commands.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 200)
        }
    }
}
