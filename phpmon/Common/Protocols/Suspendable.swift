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
}
