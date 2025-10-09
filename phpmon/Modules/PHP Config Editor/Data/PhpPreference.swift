//
//  PhpPreference.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/09/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI
import ContainerMacro

@ContainerAccess
class PhpPreference {
    let key: String

    init(container: Container = App.shared.container, key: String) {
        self.container = container
        self.key = key
    }

    internal static func persistToIniFile(key: String, value: String) throws {
        if let file = PhpEnvironments.shared.getConfigFile(forKey: key) {
            return try file.replace(key: key, value: value)
        }

        throw PhpConfigurationFile.ReplacementErrors.missingFile
    }
}

class BoolPhpPreference: PhpPreference {
    @State var value: Bool = true
}

class StringPhpPreference: PhpPreference {
    @State var value: String = ""
}
