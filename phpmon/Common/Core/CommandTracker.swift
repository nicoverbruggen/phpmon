//
//  CommandTracker.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

struct TrackedCommand: Identifiable {
    let id: UUID
    let command: String
    let startedAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    var durationText: String {
        let end = completedAt ?? Date()
        let ms = Int(end.timeIntervalSince(startedAt) * 1000)
        if isCompleted {
            return "Completed in \(ms) ms"
        } else {
            return "Running for \(ms) ms"
        }
    }
}

@MainActor
class CommandTracker: ObservableObject {
    nonisolated init() {}

    @Published private(set) var commands: [TrackedCommand] = []

    var activeCommands: [TrackedCommand] {
        commands.filter { !$0.isCompleted }
    }

    var isActive: Bool {
        !activeCommands.isEmpty
    }

    var loggingEnabled: Bool = true

    @discardableResult
    func track(_ command: String) -> UUID {
        let tracked = TrackedCommand(id: UUID(), command: command, startedAt: Date())
        commands.append(tracked)
        if loggingEnabled {
            logActiveCommands("TRACK")
        }
        return tracked.id
    }

    func complete(_ id: UUID) {
        if let index = commands.firstIndex(where: { $0.id == id }) {
            commands[index].completedAt = Date()
        }
        if loggingEnabled {
            logActiveCommands("COMPLETE")
        }
    }

    private func logActiveCommands(_ label: String) {
        if activeCommands.isEmpty {
            Log.info("[CommandTracker] [\(label)] No active commands.")
        } else {
            let list = activeCommands
                .map { "  - \($0.command) (started: \($0.startedAt))" }
                .joined(separator: "\n")
            Log.info("[CommandTracker] [\(label)] Active commands:\n\(list)")
        }
    }
}
