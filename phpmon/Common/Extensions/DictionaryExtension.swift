//
//  DictionaryExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Dictionary {
    nonisolated mutating func renameKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}
