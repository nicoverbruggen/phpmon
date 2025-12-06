//
//  Debouncer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor Debouncer {
    private var task: Task<Void, Never>?

    func debounce(for duration: TimeInterval, action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    func cancel() {
        task?.cancel()
    }
}
