//
//  CommandTracker.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
@preconcurrency import Dispatch

@MainActor
class CommandTracker: ObservableObject {
    nonisolated init() {}

    private let maxStoredCommands = 200
    @Published private(set) var commands: [LoggedCommand] = []

    var activeCommands: [LoggedCommand] {
        commands.filter { !$0.isCompleted }
    }

    var isActive: Bool {
        !activeCommands.isEmpty
    }

    @discardableResult
    func track(_ command: String, id: UUID = UUID()) -> UUID {
        let tracked = LoggedCommand(id: id, command: command, startedAt: Date())
        commands.append(tracked)
        if commands.count > maxStoredCommands {
            commands.removeFirst(commands.count - maxStoredCommands)
        }
        return tracked.id
    }

    func complete(_ id: UUID) {
        if let index = commands.firstIndex(where: { $0.id == id }) {
            commands[index].completedAt = Date()
        }
    }

    nonisolated func trackFromAnyThread(_ command: String) -> UUID {
        let id = UUID()
        Task { @MainActor in
            self.track(command, id: id)
        }
        return id
    }

    nonisolated func completeFromAnyThread(_ id: UUID) {
        Task { @MainActor in
            self.complete(id)
        }
    }
}

// MARK: - Logged Command

struct LoggedCommand: Identifiable {
    let id: UUID
    let command: String
    let startedAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    func durationText(at date: Date = Date()) -> String {
        if let completedAt {
            let duration = completedAt.timeIntervalSince(startedAt)

            if duration < 0.001 {
                let micros = max(1, Int(duration * 1_000_000))
                return "Completed in \(micros) us"
            }

            let ms = max(1, Int(duration * 1000))
            return "Completed in \(ms) ms"
        }

        let ms = max(1, Int(date.timeIntervalSince(startedAt) * 1000))
        return "Running for \(ms) ms"
    }
}
