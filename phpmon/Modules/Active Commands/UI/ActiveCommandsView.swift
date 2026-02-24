//
//  ActiveCommandsView.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct ActiveCommandsView: View {
    @ObservedObject var commandTracker: CommandTracker
    @State private var tick = false

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(commandTracker: CommandTracker? = nil) {
        self.commandTracker = commandTracker ?? App.shared.container.commandTracker
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if commandTracker.commands.isEmpty {
                    HStack {
                        Spacer()
                        Text("No commands have been tracked yet.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(30)
                        Spacer()
                    }
                } else {
                    ForEach(commandTracker.commands) { command in
                        HStack(spacing: 10) {
                            if command.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 16)
                            } else {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 16)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(command.command)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(2)
                                // tick forces re-evaluation every 200ms
                                let _ = tick
                                Text(command.durationText)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                        .id(command.id)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: commandTracker.commands.count) { _ in
                if let last = commandTracker.commands.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
        .onReceive(timer) { _ in
            if commandTracker.commands.contains(where: { !$0.isCompleted }) {
                tick.toggle()
            }
        }
    }
}
