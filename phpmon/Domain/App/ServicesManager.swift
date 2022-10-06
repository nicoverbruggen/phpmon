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

    @Published var rootServices: [String: HomebrewService] = [:]
    @Published var userServices: [String: HomebrewService] = [:]

    public static func loadHomebrewServices() async {
        let rootServiceNames = [
            PhpEnv.phpInstall.formula,
            "nginx",
            "dnsmasq"
        ]

        let normalJson = await Shell
            .pipe("sudo \(Paths.brew) services info --all --json")
            .out
            .data(using: .utf8)!

        let normalServices = try! JSONDecoder()
            .decode([HomebrewService].self, from: normalJson)
            .filter({ return rootServiceNames.contains($0.name) })

        DispatchQueue.main.async {
            ServicesManager.shared.rootServices = Dictionary(
                uniqueKeysWithValues: normalServices.map { ($0.name, $0) }
            )
        }

        guard let userServiceNames = Preferences.custom.services else {
            return
        }

        let rootJson = await Shell
            .pipe("\(Paths.brew) services info --all --json")
            .out
            .data(using: .utf8)!

        let rootServices = try! JSONDecoder()
            .decode([HomebrewService].self, from: rootJson)
            .filter({ return userServiceNames.contains($0.name) })

        ServicesManager.shared.userServices = Dictionary(
            uniqueKeysWithValues: rootServices.map { ($0.name, $0) }
        )
    }

    /**
     Dummy data for preview purposes.
     */
    func withDummyServices(_ services: [String: Bool]) -> Self {
        for (service, enabled) in services {
            let item = HomebrewService.dummy(named: service, enabled: enabled)
            self.rootServices[service] = item
        }

        return self
    }

}
