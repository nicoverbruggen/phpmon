//
//  PhpVersionNumberCollection.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/01/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

public struct PhpVersionNumberCollection: Equatable {
    let versions: [VersionNumber]

    public static func make(from versions: [String]) -> Self {
        return PhpVersionNumberCollection(
            versions: versions.map { try! VersionNumber.parse($0) }
        )
    }

    public var first: VersionNumber? {
        return self.versions.first
    }

    public var all: [VersionNumber] {
        return self.versions
    }

    /**
     Checks if any versions of PHP are valid for the constraint provided.
     Due to the complexity of evaluating these, a important test is maintained.
     More information on these constraints can be found here:
     https://getcomposer.org/doc/articles/versions.md#writing-version-constraints

     - Parameter constraint: The full constraint as a string (e.g. "^7.0")
     - Parameter strict: Whether the patch version check is strict. See more below.

     The strict mode does not matter if a patch version is provided for all versions in the collection.
     It also does not matter for certain comparisons (e.g. when dealing with wildcards).

     Strict mode assumes that any PHP version lacking precise patch information, e.g. inferred
     from Homebrew corresponds to the .0 patch version of that version. The default, which is imprecise,
     assumes that the patch version is .999, which means that in all cases the patch version check is
     always going to pass.

     **STRICT MODE (= patch precision on)**

     Given versions 8.0.? and 8.1.?, but the requirement is ^8.0.1, in strict mode only 8.1.? will
     be considered valid (8.0 translates to 8.0.0 and as such is older than 8.0.1, 8.1.0 is OK).

     When checking against actual PHP versions installed by the user (with patch precision), use
     strict mode.

     **NON-STRICT MODE (= patch precision off)**

     Given versions 8.0.? and 8.1.?, but the requirement is ^8.0.1, in non-strict mode version 8.0
     is assumed to be equal to version 8.0.999, which is actually fine if 8.0.1 is the required version.

     In non-strict mode, the patch version is ignored for regular version checks (no caret / tilde).
     If checking compatibility with general Homebrew versions of PHP, do NOT use strict mode, since
     the patch version there is not used. (The formula php@8.0 suffices for ^8.0.1.)
     */
    public func matching(constraint: String, strict: Bool = false) -> [VersionNumber] {
        if constraint == "*" {
            return self.versions
        }

        if let version = VersionNumber.make(from: constraint, type: .wildCardPatch) {
            // Wildcard for patch (e.g. "7.4.*") must match major and minor (any patch)
            return self.versions.filter { $0.hasSameMajorAndMinor(version) }
        }

        if let version = VersionNumber.make(from: constraint, type: .wildCardMinor) {
            // Strict constraint (e.g. "7.*") -> must only match major (any patch, minor)
            return self.versions.filter { $0.isSameMajorVersionAs(version) }
        }

        if let version = VersionNumber.make(from: constraint, type: .versionOnly) {
            // Strict constraint (e.g. "7.0") -> returns specific version
            return self.versions.filter { $0.isSameAs(version, strict) }
        }

        if let version = VersionNumber.make(from: constraint, type: .caretVersionRange) {
            // Caret range means that the major version is never higher but minor version can be higher
            // ^7.2 will be compatible with all versions between 7.2 and 8.0
            return self.versions.filter { $0.hasNewerMinorVersionOrPatch(version, strict) }
        }

        if let version = VersionNumber.make(from: constraint, type: .tildeVersionRange) {
            // Tilde range means that most specific digit is used as the basis.
            return self.versions.filter {
                version.patch != nil
                // If a patch is provided then the minor version cannot be bumped.
                ? $0.hasSameMajorAndMinorButNewerOrSamePatch(version, strict)
                // If a patch is not provided then the major version cannot be bumped.
                : $0.hasSameMajorButNewerOrSameMinor(version)
            }
        }

        if let version = VersionNumber.make(from: constraint, type: .greaterThanOrEqual) {
            return self.versions.filter { $0.isSameAs(version, strict) || $0.isNewerThan(version, strict) }
        }

        if let version = VersionNumber.make(from: constraint, type: .greaterThan) {
            return self.versions.filter { $0.isNewerThan(version, strict) }
        }

        if let version = VersionNumber.make(from: constraint, type: .smallerThanOrEqual) {
            return self.versions.filter { $0.isSameAs(version, strict) || $0.isOlderThan(version, strict)}
        }

        if let version = VersionNumber.make(from: constraint, type: .smallerThan) {
            return self.versions.filter { $0.isOlderThan(version, strict)}
        }

        return []
    }
}
