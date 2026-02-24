//
//  CommandHistoryView.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct CommandHistoryView: View {
    @ObservedObject var commandTracker: CommandTracker
    @State private var now = Date()

    init(commandTracker: CommandTracker? = nil) {
        self.commandTracker = commandTracker ?? App.shared.container.commandTracker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
                Text("This window displays the last executed (shell) commands. Keep in mind that only the last 200 commands are stored and displayed.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)
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
            .onChange(of: commandTracker.isActive) { isActive in
                guard isActive else { return }
                now = Date()
            }
            .onReceive(
                Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            ) { _ in
                if commandTracker.isActive {
                    now = Date()
                }
            }
        }
    }
}
