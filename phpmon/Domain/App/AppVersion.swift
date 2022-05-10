//
//  AppVersion.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class AppVersion {
    var version: String
    var build: String?
    var suffix: String?

    init(version: String, build: String?, suffix: String? = nil) {
        self.version = version
        self.build = build
        self.suffix = suffix
    }

    public static func from(_ string: String) -> AppVersion? {
        do {
            let regex = try NSRegularExpression(
                pattern: #"(?<version>(\d+)[.](\d+)([.](\d+))?)(-(?<suffix>[a-z]+)){0,1}((,|_)(?<build>\d+)){0,1}"#,
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

            var version: String = ""
            var build: String?
            var suffix: String?

            if let versionRange = Range(match.range(withName: "version"), in: string) {
                version = String(string[versionRange])
            }

            if let buildRange = Range(match.range(withName: "build"), in: string) {
                build = String(string[buildRange])
            }

            if let suffixRange = Range(match.range(withName: "suffix"), in: string) {
                suffix = String(string[suffixRange])
            }

            return AppVersion(
                version: version,
                build: build,
                suffix: suffix
            )
        } catch {
            return nil
        }
    }

    public static func fromCurrentVersion() -> AppVersion {
        return AppVersion.from("\(App.shortVersion)_\(App.bundleVersion)")!
    }

    var computerReadable: String {
        return "\(version)_\(build ?? "0")"
    }

    var humanReadable: String {
        return "\(version) (\(build ?? "???"))"
    }

}
