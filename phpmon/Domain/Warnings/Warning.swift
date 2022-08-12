//
//  Warning.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct Warning: Identifiable {
    var id = UUID()
    let command: () async -> Bool
    let name: String
    let title: String
    let paragraphs: [String]
    let url: String?

    init(
        command: @escaping () async -> Bool,
        name: String,
        title: String,
        paragraphs: [String],
        url: String?
    ) {
        self.command = command
        self.name = name
        self.title = title
        self.paragraphs = paragraphs
        self.url = url
    }

    public func applies() async -> Bool {
        return await self.command()
    }
}
