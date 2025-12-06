//
//  BrewExtensionsObservable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewExtensionsObservable: ObservableObject {
    @Published var phpVersion: String {
        didSet {
            self.loadExtensionData(for: phpVersion)
        }
    }

    @Published var extensions: [BrewPhpExtension] = []

    init(phpVersion: String) {
        self.phpVersion = phpVersion
        self.loadExtensionData(for: phpVersion)
    }

    public func loadExtensionData(for version: String) {
        let tapFormulae = BrewTapFormulae.from(
            App.shared.container,
            tap: "shivammathur/homebrew-extensions"
        )

        if let filteredTapFormulae = tapFormulae[version] {
            self.extensions = filteredTapFormulae
        }
    }
}
