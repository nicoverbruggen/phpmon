//
//  StringExtension.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//
import Foundation

extension String {

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }

    func localized(_ args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }

    func countInstances(of stringToFind: String) -> Int {
        if stringToFind.isEmpty {
            return 0
        }

        var count = 0
        var searchRange: Range<String.Index>?

        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }

        return count
    }

    subscript (r: Range<String.Index>) -> String {
        let start = r.lowerBound
        let end = r.upperBound
        return String(self[start ..< end])
    }

    // Code taken from: https://sarunw.com/posts/how-to-compare-two-app-version-strings-in-swift/
    /*
     <1> We split the version by period (.).
     <2> Then, we find the difference of digit that we will zero pad.
     <3> If there are no differences, we don't need to do anything and use simple .compare.
     <4> We populate an array of missing zero.
     <5> We add zero pad array to a version with a fewer period and zero.
     <6> We user array components to build back our versions from components and compare them.
         This time it will have the same period and number of digit.
     */
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter) // <1>
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count // <2>

        if zeroDiff == 0 { // <3>
            // Same format, compare normally
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff)) // <4>
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros) // <5>
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric) // <6>
        }
    }

}
