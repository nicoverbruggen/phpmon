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

    private var loadTask: Task<Void, Never>?

    init(phpVersion: String) {
        self.phpVersion = phpVersion
        self.loadExtensionData(for: phpVersion)
    }

    public func loadExtensionData(for version: String) {
        loadTask?.cancel()
        extensions = []
        loadTask = Task {
            let tapFormulae = await BrewTapFormulae.from(
                App.shared.container,
                tap: "shivammathur/homebrew-extensions"
            )
            guard !Task.isCancelled else { return }
            self.extensions = tapFormulae[version] ?? []
        }
    }
}
