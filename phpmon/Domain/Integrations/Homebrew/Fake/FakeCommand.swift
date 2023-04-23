//
//  FakeCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeCommand: BrewCommand {
    let version: String

    init(version: String) {
        self.version = version
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        onProgress(.create(value: 0.2, title: "Hello", description: "Doing the work"))
        await delay(seconds: 2)
        onProgress(.create(value: 0.5, title: "Hello", description: "Doing some more work"))
        await delay(seconds: 1)
        onProgress(.create(value: 1, title: "Hello", description: "Job's done"))
    }
}
