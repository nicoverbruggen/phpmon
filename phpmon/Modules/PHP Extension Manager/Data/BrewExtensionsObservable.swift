//
//  BrewExtensionsObservable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewExtensionsObservable: ObservableObject {
    @Published var extensions: [BrewPhpExtension] = []

    public func loadExtensionData(for version: String) {
        let tapFormulae = BrewTapFormulae.from(tap: "shivammathur/homebrew-extensions")

        if let filteredTapFormulae = tapFormulae[version] {
            self.extensions = filteredTapFormulae
        }
    }
}
