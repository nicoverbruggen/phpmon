//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class Container {
    // Primary
    var shell: ShellProtocol!
    var filesystem: FileSystemProtocol!
    var command: CommandProtocol!
    var paths: Paths!

    // Secondary (uses primary instances above)
    var preferences: Preferences!
    var phpEnvs: PhpEnvironments!
    var favorites: Favorites!
    var warningManager: WarningManager!

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
        // These are the most basic building blocks. We need these before
        // any of the other classes can be initialized!
        self.shell = RealShell(container: self)
        self.filesystem = RealFileSystem(container: self)
        self.command = RealCommand()
        self.paths = Paths(container: self)

        // Please note that the order in which these are initialized, matters!
        // For example, preferences leverages the Paths instance, so don't just
        // swap these around for no reason... the order is very intentional.
        self.preferences = Preferences(container: self)
        self.phpEnvs = PhpEnvironments(container: self)
        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }
}
