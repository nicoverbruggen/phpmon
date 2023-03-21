//
//  BrewCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct BrewCommandProgress {
    let value: Double
    let title: String
    let description: String

    public static func create(value: Double, title: String, description: String) -> BrewCommandProgress {
        return BrewCommandProgress(value: value, title: title, description: description)
    }
}

protocol BrewCommand {
    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws
}

extension BrewCommand {

}

struct BrewCommandError: Error {
    let error: String
}
