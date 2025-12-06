//
//  Suspendable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/12/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 A protocol for actors that manage filesystem watchers and can temporarily
 suspend their responses to changes.

 This is useful when the application itself makes changes to watched files,
 preventing duplicate work or unwanted side effects.
 */
protocol Suspendable: Actor {
    /**
     Suspends responding to filesystem events.
     Events are still observed but handlers won't fire.
     */
    func suspend() async

    /**
     Resumes responding to filesystem events.
     Handlers will fire normally for observed events.
     */
    func resume() async

    /**
     Executes an action while suspended, ensuring resume happens
     even if the action throws.

     - Parameter action: The async throwing closure to execute while suspended
     - Returns: The result of the action
     - Throws: Rethrows any error from the action
     */
    func withSuspended<T>(_ action: () async throws -> T) async rethrows -> T
}

extension Suspendable {
    /**
     Default implementation of withSuspended that ensures proper
     suspend/resume lifecycle even when errors occur.
     */
    func withSuspended<T>(_ action: () async throws -> T) async rethrows -> T {
        await suspend()
        do {
            let result = try await action()
            await resume()
            return result
        } catch {
            await resume()
            throw error
        }
    }
}
