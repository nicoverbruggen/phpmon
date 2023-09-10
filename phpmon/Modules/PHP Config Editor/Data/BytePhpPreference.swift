//
//  BytePhpPreference.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/09/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class BytePhpPreference: PhpPreference {
    enum UnitOption: String, CaseIterable {
        case kilobyte = "K"
        case megabyte = "M"
        case gigabyte = "G"

        public var displayValue: String {
            switch self {
            case .kilobyte: return "KB"
            case .megabyte: return "MB"
            case .gigabyte: return "GB"
            }
        }
    }

    // MARK: Internal Values

    var internalValue: String

    var value: Int = 256 {
        didSet { updatedFieldValue() }
    }

    var unit: UnitOption = .megabyte {
        didSet { updatedFieldValue() }
    }

    override init(key: String) {
        let value = Command.execute(
            path: Paths.php, arguments: ["-r", "echo ini_get('\(key)');"],
            trimNewlines: false
        )

        self.internalValue = value
        if let (unit, value) = BytePhpPreference.readFrom(internalValue: self.internalValue) {
            self.unit = unit
            self.value = value
        }
        super.init(key: key)
    }

    // MARK: Save Value

    private func updatedFieldValue() {
        internalValue = "\(value)\(unit.rawValue)"
    }

    public static func readFrom(internalValue: String) -> (UnitOption, Int)? {
        let pattern = "(-?\\d+)([KMG]?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: internalValue.utf16.count)

        if let match = regex.firstMatch(in: internalValue, options: [], range: range) {
            let valueRange = match.range(at: 1)
            let unitRange = match.range(at: 2)

            if let value = Int(internalValue[Range(valueRange, in: internalValue)!]) {
                let unitString = internalValue[Range(unitRange, in: internalValue)!] as String
                return (UnitOption(rawValue: unitString) ?? UnitOption.kilobyte, value)
            }
        }

        return nil
    }
}
