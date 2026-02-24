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

    // Timestamp used to compute duration labels in the list; updated when tick fires
    @State private var now = Date()

    // Tracks whether the window view is currently visible
    @State private var isWindowVisible = false

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
                            now: now,
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
            .onAppear {
                // Mark the window as visible so duration ticking can start
                isWindowVisible = true
                now = Date()
            }
            .onDisappear {
                // Stop ticking when the window disappears
                isWindowVisible = false
            }
            .onReceive(Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()) { _ in
                // Only update running commands if the window is visible + there's command IDs that are:
                // - visible (in window, based on scroll position)
                // - running (so we need to update the timestamp periodically)
                if commandTracker.isActive, shouldTick {
                    now = Date()
                }
            }
        }
    }

    private var shouldTick: Bool {
        isWindowVisible && !visibleCommandIds.isEmpty
    }
}
