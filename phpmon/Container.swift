//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class Container {
    var shell: ShellProtocol!
    var favorites: Favorites!
    var warningManager: WarningManager!

    init() {}

    public func prepare() {
        self.shell = RealShell()
        // TODO: filesystem etc.

        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }

    public func overrideWith(config: TestableConfiguration) {
        self.shell = TestableShell(expectations: config.shellOutput)
    }
}

protocol ContainerAccess {
    var container: Container { get set }
}
