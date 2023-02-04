//
//  CaskFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct CaskFile {
    var properties: [String: String]

    public static func from(url: URL) -> CaskFile? {
        let string = try? String(contentsOf: url)

        guard let string else {
            return nil
        }

        let lines = string.split(separator: "\n")
            .filter { $0 != "" }

        if lines.count < 4 {
            return nil
        }

        if !lines.first!.starts(with: "cask") || !lines.last!.starts(with: "end") {
            return nil
        }

        var props: [String: String] = [:]

        lines.forEach { line in
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = text.split(separator: " ")

            if parts.count == 2 {
                props[String(parts[0])] = String(parts[1])
                    .replacingOccurrences(of: "\'", with: "")
            }
        }

        return CaskFile(properties: props)
    }

}
