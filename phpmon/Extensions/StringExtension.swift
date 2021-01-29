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
    
    func countInstances(of stringToFind: String) -> Int {
        if (stringToFind.isEmpty) {
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
}
