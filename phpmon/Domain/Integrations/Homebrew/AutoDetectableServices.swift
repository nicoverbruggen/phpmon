//
//  DetectableService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

struct DetectableService: Hashable {
    let binary: String
    let service: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(service)
    }
}

actor AutoDetectableServices {

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Static Instance

    public static let shared = AutoDetectableServices(App.shared.container)

    /**
     The Homebrew services that should be automatically
     detected and show up in the list of managed services.
     */
    static let DetectableHomebrewServices: Set<DetectableService> = [
        DetectableService(binary: "$(brew --prefix)/bin/mailhog", service: "mailhog"),
        DetectableService(binary: "$(brew --prefix)/bin/postgres", service: "postgresql"),
        DetectableService(binary: "$(brew --prefix)/bin/mysql", service: "mysql"),
        DetectableService(binary: "$(brew --prefix)/bin/mariadb", service: "mariadb"),
        DetectableService(binary: "$(brew --prefix)/bin/redis-server", service: "redis")
    ]

    private(set) var foundServices: Set<DetectableService> = []

    func discoverServices() async {
        foundServices = Set(Self.DetectableHomebrewServices.filter { service in
            container.filesystem.isExecutableFile(
                service.binary.replacing("$(brew --prefix)", with: brewPrefix)
            )
        })
    }

    private var brewPrefix: String {
        if !container.paths.binPath.hasSuffix("/bin") {
            return container.paths.binPath
        }

        return String(container.paths.binPath.dropLast("/bin".count))
    }
}
