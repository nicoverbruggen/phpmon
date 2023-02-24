//
//  Warning.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct Warning: Identifiable, Hashable {
    var id = UUID()
    let command: () async -> Bool
    let name: String
    let title: String
    let paragraphs: () -> [String]
    let url: String?

    /**
     - Parameters:
        - command: The command that, if it returns true, means that a warning applies
        - name: The internal name or description for this warning
        - title: The title displayed for the user
        - paragraphs: The main body of text displayed for the user
        - url: The URL that one can navigate to for more information (if applicable)
     */
    init(
        command: @escaping () async -> Bool,
        name: String,
        title: String,
        paragraphs: @escaping () -> [String],
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

    public static func == (lhs: Warning, rhs: Warning) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
