//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class Container {
    var shell: ShellProtocol!
    var filesystem: FileSystemProtocol!
    var command: CommandProtocol!

    var paths: Paths!
    var phpEnvs: PhpEnvironments!

    var favorites: Favorites!
    var warningManager: WarningManager!

    init() {}

    public func prepare() {
        self.shell = RealShell(container: self)
        self.filesystem = RealFileSystem(container: self)
        self.command = RealCommand()

        self.paths = Paths(container: self)
        self.phpEnvs = PhpEnvironments(container: self)

        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }

    public func overrideWith(config: TestableConfiguration) {
        self.shell = TestableShell(expectations: config.shellOutput)
        self.filesystem = TestableFileSystem(files: config.filesystem)
        self.command = TestableCommand(commands: config.commandOutput)
    }

    public static func real() -> Container {
        let container = Container()
        container.prepare()
        return container
    }
}
