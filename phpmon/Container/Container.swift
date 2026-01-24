//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class Container: @unchecked Sendable {
    // MARK: - Variables

    // Primary
    private(set) var filesystem: FileSystemProtocol!
    private(set) var paths: Paths!
    private(set) var shell: ShellProtocol!
    private(set) var command: CommandProtocol!
    private(set) var webApi: WebApiProtocol!

    // Secondary (uses primary instances above)
    private(set) var preferences: Preferences!
    private(set) var phpEnvs: PhpEnvironments!
    private(set) var favorites: Favorites!
    private(set) var warningManager: WarningManager!

    // Track initial preparation step
    private var bound: Bool = false

    // MARK: - Initializers

    ///
    /// The initializer is empty. You must call `bind` to enable the container.
    ///
    /// To avoid issues with unsafe access, the actual objects are set in `bind`.
    ///
    /// `self` is not available in this constructor, after all. The alternative
    /// is to use lazy variables here, but I don't think it's that clean, especially
    /// given the other initializers available via the extensions.
    ///
    init() {}

    ///
    /// Creates new instances of all elements belonging to the `Container`, while referencing
    /// the `Container` itself and passing the reference on to each component that needs it.
    ///
    /// You can only call this method once. Running it again will crash with `fatalError`,
    /// because it would cause all sorts of issues if individual DI elements are swapped out
    /// without proper deinitialization.
    ///
    /// (Swapping instances for specific dependencies can be introduced later with dedicated
    /// methods if it ever becomes truly necessary.)
    ///
    /// - Parameter coreOnly: Only binds `shell`, `filesystem`, `command`, `paths` and `webApi`.
    ///   Use this to prevent slowing down tests for a minimal container.
    ///
    public func bind(coreOnly: Bool = false) {
        if self.bound {
            fatalError("You cannot call `bind` on a Container more than once.")
        }

        defer {
            self.bound = true
        }

        // These are the most basic building blocks. We need these before
        // any of the other classes can be initialized!
        self.filesystem = RealFileSystem(container: self)
        self.paths = Paths(container: self)
        self.shell = RealShell(binPath: paths.binPath)
        self.command = RealCommand()
        self.webApi = RealWebApi(container: self)

        if coreOnly {
            return
        }

        // Please note that the order in which these are initialized, matters!
        // For example, preferences leverages the Paths instance, so don't just
        // swap these around for no reason... the order is very intentional.
        self.preferences = Preferences(container: self)
        self.phpEnvs = PhpEnvironments(container: self)
        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }

    /**
     Manually specify what testable overrides need to be active for the `Container`.

     Only used for testing purposes, either via `TestableConfiguration` or for
     explicit initialization of a fake Container instance.
     */
    public func overrideFake(
        shellExpectations: [String: BatchFakeShellOutput] = [:],
        fileSystemFiles: [String: FakeFile] = [:],
        commands: [String: String] = [:],
        webApiGetResponses: [URL: FakeWebApiResponse] = [:],
        webApiPostResponses: [URL: FakeWebApiResponse] = [:]
    ) {
        self.shell = TestableShell(expectations: shellExpectations)
        self.filesystem = TestableFileSystem(files: fileSystemFiles)
        self.command = TestableCommand(commands: commands)
        self.webApi = TestableWebApi(
            getResponses: webApiGetResponses,
            postResponses: webApiPostResponses
        )

        // We will also re-initialize PhpEnvironments due to altered dependencies
        self.phpEnvs = PhpEnvironments(container: self)
    }

    /**
     Use a `TestableConfiguration` as the basis for shell, filesystem and more.
     This is used for testing scenarios to avoid needing to have a specific system configuration.
     Ideal for feature or UI tests, where a complete "computer configuration" needs to be mimicked.
     */
    public func overrideWith(config: TestableConfiguration) {
        self.overrideFake(
            shellExpectations: config.shellOutput,
            fileSystemFiles: config.filesystem,
            commands: config.commandOutput,
            webApiGetResponses: config.apiGetResponses,
            webApiPostResponses: config.apiPostResponses
        )
    }
}
