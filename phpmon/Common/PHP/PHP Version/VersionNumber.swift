//
//  PhpVersionNumber.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/01/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 A version number that is (mostly) compatible with the semantic versioning standard.
 For more information about semantic versioning, see: https://semver.org/

 - Note: If you want to check version constraints for PHP versions, please see `PhpVersionNumberCollection`.
 */
public struct VersionNumber: Equatable, Hashable {
    let major: Int
    let minor: Int
    let patch: Int?

    var text: String {
        return self.patch == nil
        ? "\(major).\(minor)"
        : "\(major).\(minor).\(patch!)"
    }

    public func patch(_ strictFallback: Bool = true, _ constraint: VersionNumber? = nil) -> Int {
        return patch ?? (strictFallback ? 0 : constraint?.patch ?? 999)
    }

    public var long: String {
        return "\(major).\(minor).\(patch ?? 0)"
    }

    public var short: String {
        return "\(major).\(minor)"
    }

    public enum MatchType: String {
        case versionOnly = #"^(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case wildCardPatch =  #"^(?<major>\d+).(?<minor>\d+).?(?<patch>\*)?\z"#
        case wildCardMinor =  #"^(?<major>\d+).(?<minor>\*)?\z"#
        case caretVersionRange = #"^\^(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case tildeVersionRange = #"^~(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case greaterThanOrEqual = #"^>=(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case greaterThan = #"^>(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case smallerThanOrEqual = #"^<=(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
        case smallerThan = #"^<(?<major>\d+).(?<minor>\d+).?(?<patch>\d+)?\z"#
    }

    public static func parse(_ text: String) throws -> Self {
        guard let versionText = VersionExtractor.from(text) else {
            throw VersionParseError()
        }

        return Self.make(from: versionText)!
    }

    public static func make(from versionString: String, type: MatchType = .versionOnly) -> Self? {
        let regex = try! NSRegularExpression(pattern: type.rawValue, options: [])

        let match = regex.matches(
            in: versionString,
            options: [],
            range: NSRange(location: 0, length: versionString.count)
        ).first

        guard let match else { return nil }

        let major = Int(versionString[Range(match.range(withName: "major"), in: versionString)!])!
        var minor: Int = 0
        var patch: Int?

        if let minorRange = Range(match.range(withName: "minor"), in: versionString) {
            let value = versionString[minorRange] as String
            // Zero is the fallback if a wildcard was used
            minor = Int(value) ?? 0
        }

        if let patchRange = Range(match.range(withName: "patch"), in: versionString) {
            let value = versionString[patchRange] as String
            // nil is the fallback if a wildcard was used
            patch = Int(value) ?? nil
        }

        return Self(major: major, minor: minor, patch: patch)
    }

    // MARK: Comparison Logic

    internal func isSameMajorVersionAs(_ version: VersionNumber) -> Bool {
        return self.major == version.major
    }

    internal func isSameAs(_ version: VersionNumber, _ strict: Bool = true) -> Bool {
        return self.major == version.major
            && self.minor == version.minor
            && (strict ? self.patch(strict, version) == version.patch(strict) : true)
    }

    internal func hasSameMajorAndMinor(_ version: VersionNumber) -> Bool {
        return self.major == version.major && self.minor == version.minor
    }

    internal func isNewerThan(_ version: VersionNumber, _ strict: Bool = true) -> Bool {
        return (
            self.major > version.major ||
            self.major == version.major && self.minor > version.minor ||
            self.major == version.major && self.minor == version.minor
                && self.patch(strict) > version.patch(strict)
        )
    }

    internal func isOlderThan(_ version: VersionNumber, _ strict: Bool = true) -> Bool {
        return (
            self.major < version.major ||
            self.major == version.major && self.minor < version.minor ||
            self.major == version.major && self.minor == version.minor
            && self.patch(strict) < version.patch(strict)
        )
    }

    internal func hasNewerMinorVersionOrPatch(_ version: VersionNumber, _ strict: Bool = true) -> Bool {
        return self.major == version.major &&
        (
            (self.minor == version.minor && self.patch(strict) >= version.patch(strict, self))
            || self.minor > version.minor
        )
    }

    internal func hasSameMajorAndMinorButNewerOrSamePatch(_ version: VersionNumber, _ strict: Bool = true) -> Bool {
        return self.major == version.major && self.minor == version.minor
            && self.patch(strict, version) >= version.patch(strict)
    }

    internal func hasSameMajorButNewerOrSameMinor(_ version: VersionNumber) -> Bool {
        return self.major == version.major
            && self.minor >= version.minor
    }
}
