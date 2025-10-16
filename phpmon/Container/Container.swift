//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class Container {
    // Core abstractions
    var shell: ShellProtocol!
    var filesystem: FileSystemProtocol!
    var command: CommandProtocol!

    // Extra abstractions
    var paths: Paths!
    var phpEnvs: PhpEnvironments!
    var favorites: Favorites!
    var warningManager: WarningManager! // pending rename?

    ///
    /// The initializer is empty. You must call `prepare` to enable the container.
    /// To avoid issues with unsafe access, the actual objects are set in `prepare`.
    /// `self` is not available in this constructor, after all. The alternative
    /// is to use lazy variables here, but I don't think it's that clean, especially
    /// given the other initializers available via the extensions.
    ///
    init() {}

    ///
    /// Creates new instances belonging to the container, while referencing
    /// the container itself and passing the reference on to each component that needs it.
    ///
    public func prepare() {
        // Core
        self.shell = RealShell(container: self)
        self.filesystem = RealFileSystem(container: self)
        self.command = RealCommand()

        // Extra
        self.paths = Paths(container: self)
        self.phpEnvs = PhpEnvironments(container: self)
        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }
}
