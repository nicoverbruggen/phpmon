//
//  Container.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// Nonisolated: the DI container hands out the leaf services (shell, filesystem, command,
// paths — all nonisolated) and must be reachable from off-main / actor contexts. It is
// @unchecked Sendable because in Release its slots are bound once at startup and never
// re-swapped. DEBUG configuration profiles and tests do re-swap fakes via `overrideFake`,
// but always on the main actor during controlled startup or test setup, before any
// background work holds a reference to the instances being replaced.
nonisolated class Container: @unchecked Sendable {
    // MARK: - System Context

    var systemContext = SystemContext()

    // MARK: - Variables

    // Primary
    private(set) var filesystem: FileSystemProtocol!
    private(set) var paths: Paths!
    private(set) var shell: ShellProtocol!
    private(set) var command: CommandProtocol!
    private(set) var commandTracker: CommandTracker!
    private(set) var webApi: WebApiProtocol!
    private(set) var privilegedCommandRunner: PrivilegedCommandRunner!

    // Secondary (uses primary instances above)
    private(set) var preferences: Preferences!
    private(set) var phpEnvs: PhpEnvironments!
    private(set) var valet: Valet!
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

    public func withFakeSystemContext(
        architecture: String? = nil,
        configuredShell: String? = nil
    ) {
        if bound {
            fatalError("System context must be overridden before `bind()` is called.")
        }

        self.systemContext = SystemContext(
            architectureOverride: architecture,
            configuredShellOverride: configuredShell
        )
    }

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
    /// - Parameter commandTracking: When enabled, connects decorated RealShell and RealCommand.
    ///   Use this if you want to disable tracking (shell) command statuses, since it's on by default.
    ///
    @MainActor
    public func bind(coreOnly: Bool = false, commandTracking: Bool = true) {
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
        self.commandTracker = CommandTracker()

        let baseShellHandler = RealShell(binPath: paths.binPath, preferredShell: systemContext.shell.resolved)
        let baseCommandHandler = RealCommand()

        // Depending on whether we need command tracking wired up, we will use different real handlers
        if commandTracking {
            self.shell = TrackedShell(shell: baseShellHandler, commandTracker: commandTracker)
            self.command = TrackedCommand(command: baseCommandHandler, commandTracker: commandTracker)
        } else {
            self.shell = baseShellHandler
            self.command = baseCommandHandler
        }

        self.webApi = RealWebApi(container: self)
        self.privilegedCommandRunner = RealPrivilegedCommandRunner()

        if coreOnly {
            return
        }

        // Please note that the order in which these are initialized, matters!
        // For example, preferences leverages the Paths instance, so don't just
        // swap these around for no reason... the order is very intentional.
        self.preferences = Preferences(container: self)
        self.valet = Valet(container: self)
        self.phpEnvs = PhpEnvironments(container: self)
        self.favorites = Favorites()
        self.warningManager = WarningManager(container: self)
    }

    /**
     Manually specify what testable overrides need to be active for the `Container`.

     Only used for testing purposes, either via `TestableConfiguration` or for
     explicit initialization of a fake Container instance.
     */
    @MainActor
    public func overrideFake(
        shellExpectations: [String: BatchFakeShellOutput] = [:],
        fileSystemFiles: [String: FakeFile] = [:],
        fileSystem: TestableFileSystem? = nil,
        commands: [String: String] = [:],
        webApiGetResponses: [URL: FakeWebApiResponse] = [:],
        webApiPostResponses: [URL: FakeWebApiResponse] = [:],
        privilegedCommandRunner: PrivilegedCommandRunner? = nil,
        commandTracking: Bool = true,
    ) {
        self.commandTracker = CommandTracker()

        let filesystem = fileSystem ?? TestableFileSystem(files: fileSystemFiles)

        // Depending on whether we want to fire command tracking, load different handlers
        if commandTracking {
            self.shell = TrackableTestableShell(expectations: shellExpectations, filesystem: filesystem, commandTracker)
            self.command = TrackableTestableCommand(commands: commands, commandTracker)
        } else {
            self.shell = TestableShell(expectations: shellExpectations, filesystem: filesystem)
            self.command = TestableCommand(commands: commands)
        }

        self.filesystem = filesystem

        self.webApi = TestableWebApi(
            getResponses: webApiGetResponses,
            postResponses: webApiPostResponses
        )

        self.privilegedCommandRunner = privilegedCommandRunner ?? DisabledPrivilegedCommandRunner()

        // Minimal containers also need local Valet state when fake PHP environments are loaded.
        if self.valet == nil {
            self.valet = Valet(container: self)
        }

        // We will also re-initialize PhpEnvironments due to altered dependencies
        self.phpEnvs = PhpEnvironments(container: self)

        // Populate the current installation eagerly, as tests expect. The blocking
        // (synchronous) load is acceptable here because this container is backed by
        // fakes, so the probe's I/O resolves instantly. The real container defers
        // this to the async load performed during the startup environment checks.
        self.phpEnvs.currentInstall = ActivePhpInstallation.loadSync(self)
    }

    /**
     Use a `TestableConfiguration` as the basis for shell, filesystem and more.
     This is used for testing scenarios to avoid needing to have a specific system configuration.
     Ideal for feature or UI tests, where a complete "computer configuration" needs to be mimicked.
     */
    @MainActor
    public func overrideWith(config: TestableConfiguration) {
        self.overrideFake(
            shellExpectations: config.shellOutput,
            fileSystemFiles: config.filesystem,
            commands: config.commandOutput,
            webApiGetResponses: config.apiGetResponses,
            webApiPostResponses: config.apiPostResponses,
            privilegedCommandRunner: UITestPrivilegedCommandRunner()
        )
    }
}
