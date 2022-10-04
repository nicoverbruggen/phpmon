//
//  Testables.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

// swiftlint:disable colon trailing_comma
class Testables {

    typealias Configuration = [String: BatchFakeShellOutput]

    // TODO: Complete broken configuration setup
    static var broken: Configuration {
        return [
            "php -v"                            : .instant(""),
            "ls /opt/homebrew/opt | grep php"   : .instant(""),
        ]
    }

    // TODO: All expected, correct Terminal responses
    static var working: Configuration {
        return [:]
    }

}
