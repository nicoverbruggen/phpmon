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

    override init(_ container: Container, key: String) {
        let value = container.command.execute(
            path: container.paths.php, arguments: ["-r", "echo ini_get('\(key)');"],
            trimNewlines: false
        )

        self.internalValue = value
        if let (unit, value) = BytePhpPreference.readFrom(internalValue: self.internalValue) {
            self.unit = unit
            self.value = value
        }

        super.init(container, key: key)
    }

    // MARK: Save Value

    private func updatedFieldValue() {
        if value == -1 {
            // In case we're dealing with unlimited value, we don't need a unit
            internalValue = "-1"
        } else {
            // We need to append the unit otherwise
            internalValue = "\(value)\(unit.rawValue)"
        }

        do {
            try PhpPreference.persistToIniFile(key: self.key, value: self.internalValue)
            Log.info("The preference \(key) was updated to: \(value)")
        } catch {
            Log.info("The preference \(key) could not be updated")
        }
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
