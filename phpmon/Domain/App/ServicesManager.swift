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

    public static func loadHomebrewServices(completed: (() -> Void)? = nil) {
        let rootServiceNames = [
            PhpEnv.phpInstall.formula,
            "nginx",
            "dnsmasq"
        ]

        DispatchQueue.global(qos: .background).async {
            let data = Shell
                .pipe("sudo \(Paths.brew) services info --all --json", requiresPath: true)
                .data(using: .utf8)!

            let services = try! JSONDecoder()
                .decode([HomebrewService].self, from: data)
                .filter({ return rootServiceNames.contains($0.name) })

            DispatchQueue.main.async {
                ServicesManager.shared.rootServices = Dictionary(
                    uniqueKeysWithValues: services.map { ($0.name, $0) }
                )
            }
        }

        let userServiceNames = Preferences.custom.services ?? []

        DispatchQueue.global(qos: .background).async {
            let data = Shell
                .pipe("\(Paths.brew) services info --all --json", requiresPath: true)
                .data(using: .utf8)!

            let services = try! JSONDecoder()
                .decode([HomebrewService].self, from: data)
                .filter({ return userServiceNames.contains($0.name) })

            DispatchQueue.main.async {
                ServicesManager.shared.userServices = Dictionary(
                    uniqueKeysWithValues: services.map { ($0.name, $0) }
                )
                completed?()
            }
        }
    }

    func loadData() {
        Self.loadHomebrewServices()
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
