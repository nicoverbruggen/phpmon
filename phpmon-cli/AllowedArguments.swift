//
//  AllowedArguments.swift
//  phpmon-cli
//
//  Created by Nico Verbruggen on 20/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum AllowedArguments: String, CaseIterable {
    case use = "use"
    case performSwitch = "switch"
    case help = "help"
    
    static func has(_ string: String) -> Bool {
        return Self.allCases.contains { arg in
            return arg.rawValue == string
        }
    }
    
    static var rawValues: [String] {
        return Self.allCases.map { $0.rawValue }
    }
}
