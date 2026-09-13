//
//  DetectableService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

// `nonisolated`: a pure value type used in `Set` operations from off-main/async contexts
// (`discoverServices`). Without it, the synthesized `Hashable`/`Equatable` conformance is
// main-actor-isolated and can't be used when filtering the set off the main actor.
nonisolated struct DetectableService: Hashable, Sendable {
    let service: String

    init(service: String) {
        self.service = service
    }

    var servicePrefix: String {
        return "\(service)@"
    }

    func matchesInstalledFormula(_ formula: String) -> Bool {
        if formula == service {
            return true
        }

        return formula.hasPrefix(servicePrefix)
    }

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

    // Isolated to the main actor because the initializer reads `App.shared.container`
    // (main-actor state). Both call sites (Startup+Launch, ServicesRegistry) are already
    // on the main actor, so this does not constrain existing usage.
    @MainActor public static let shared = AutoDetectableServices(App.shared.container)

    /**
     The Homebrew services that should be automatically
     detected and show up in the list of managed services.
     */
    static let DetectableHomebrewServices: Set<DetectableService> = [
        DetectableService(service: "mailhog"),
        DetectableService(service: "postgresql"),
        DetectableService(service: "mysql"),
        DetectableService(service: "mariadb"),
        DetectableService(service: "redis")
    ]

    private(set) var foundServices: Set<DetectableService> = []

    func discoverServices() async {
        let formulae = await installedFormulae()

        foundServices = Set(Self.DetectableHomebrewServices.filter { service in
            formulae.contains(where: service.matchesInstalledFormula)
        })
    }

    private func installedFormulae() async -> [String] {
        return await container.shell
            .pipe("\(container.paths.brew) list --formula")
            .out
            .split(separator: "\n")
            .map { String($0) }
    }
}
