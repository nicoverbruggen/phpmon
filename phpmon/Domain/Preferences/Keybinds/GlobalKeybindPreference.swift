//
//  GlobalKeybindPreference.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

struct GlobalKeybindPreference: Codable, CustomStringConvertible {

    // MARK: - Internal variables

    let function: Bool
    let control: Bool
    let command: Bool
    let shift: Bool
    let option: Bool
    let capsLock: Bool
    let carbonFlags: UInt32
    let characters: String?
    let keyCode: UInt32

    // MARK: - How the keybind is display in Preferences

    var description: String {
        var stringBuilder = ""
        if self.function {
            stringBuilder += "Fn"
        }
        if self.control {
            stringBuilder += "⌃"
        }
        if self.option {
            stringBuilder += "⌥"
        }
        if self.command {
            stringBuilder += "⌘"
        }
        if self.shift {
            stringBuilder += "⇧"
        }
        if self.capsLock {
            stringBuilder += "⇪"
        }
        if let characters = self.characters {
            stringBuilder += characters.uppercased()
        }
        return "\(stringBuilder)"
    }

    // MARK: - Persisting data to UserDefaults (as JSON)

    public func toJson() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }

    public static func fromJson(_ string: String?) -> GlobalKeybindPreference? {
        if string == nil {
            return nil
        }

        if let jsonData = string!.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(GlobalKeybindPreference.self, from: jsonData)
            } catch {
                return nil
            }
        }
        return nil
    }
}
