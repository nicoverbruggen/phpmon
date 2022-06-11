//
//  ServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class ServicesManager: ObservableObject {

    static var shared = ServicesManager()

    @Published var services: [String: HomebrewService] = [:]

    func loadData() {
        HomebrewService.loadAll { services in
            self.services = Dictionary(
                uniqueKeysWithValues: services.map { ($0.name, $0) }
            )
        }
    }

    /**
     Dummy data for preview purposes.
     */
    func withDummyServices(_ services: [String: Bool]) -> Self {
        for (service, enabled) in services {
            let item = HomebrewService.dummy(named: service, enabled: enabled)
            self.services[service] = item
        }

        return self
    }

}
