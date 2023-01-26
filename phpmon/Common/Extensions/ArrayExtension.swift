//
//  ArrayExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Array {
    /**
     Sourced from Stack Overflow
     https://stackoverflow.com/a/33540708
     */
    func chunked(by distance: Int) -> [[Element]] {
        let indicesSequence = stride(from: startIndex, to: endIndex, by: distance)
        let array: [[Element]] = indicesSequence.map {
            let newIndex = $0.advanced(by: distance) > endIndex ? endIndex : $0.advanced(by: distance)
            return Array(self[$0 ..< newIndex])
        }
        return array
    }
}
