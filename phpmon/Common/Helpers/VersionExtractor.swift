//
//  VersionExtractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class VersionExtractor {

    /**
     This attempts to extract the version number from any given string.
     */
    public static func from(_ string: String) -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: #"(?<version>(\d+)(.)(\d+)((.)(\d+))?)"#,
                options: []
            )

            let match = regex.matches(
                in: string,
                options: [],
                range: NSRange(location: 0, length: string.count)
            ).first

            guard let match = match else {
                return nil
            }

            let range = Range(
                match.range(withName: "version"),
                in: string
            )!

            return String(string[range])
        } catch {
            return nil
        }
    }

}
