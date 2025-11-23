//
//  RCFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/01/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

struct RCFile {
    let path: String?
    let fields: [String: String]

    static func fromPath(_ path: String) -> RCFile? {
        do {
            let text = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            return RCFile(path: path, contents: text)
        } catch {
            return nil
        }
    }

    init(path: String? = nil, contents: String) {
        var fields: [String: String] = [:]

        contents
            .split(separator: "\n")
            .forEach({ line in
                if line.contains("=") {
                    let content = line.split(separator: "=")
                    let key = String(content[0])
                        .trimmingCharacters(in: .whitespaces)
                        .replacing("\"", with: "")
                    if key.starts(with: "#") {
                        return
                    }
                    let value = String(content[1])
                        .trimmingCharacters(in: .whitespaces)
                        .replacing("\"", with: "")
                    fields[key] = value
                }
            })

        self.path = path
        self.fields = fields
    }
}
