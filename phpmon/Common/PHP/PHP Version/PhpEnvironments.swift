//
//  PhpEnvironments.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpEnvironments {
    var container: Container

    // MARK: - Initializer

    /**
     Loads the currently active PHP installation upon startup. May be empty.
     */
    init(container: Container) {
        self.container = container
        self.currentInstall = ActivePhpInstallation.load(container)
    }

    /**
     Loads the valid HomebrewPackage information.
     If invalid, this will prevent PHP Monitor from starting correctly.
     */
    func getHomebrewInformation() async {
        // Let's see which formula we need to check
        var formulaToLoad = "php"

        // Depending on whether the `shivammathur/php` tap is installed, this command will vary
        if BrewDiagnostics.shared.installedTaps.contains("shivammathur/php") {
            formulaToLoad = "shivammathur/php/php"
        }

        // Let's check the alias by using `brew info`
        let brewPhpAlias = await container.shell.pipe("\(container.paths.brew) info \(formulaToLoad) --json").out

        // Remove any non-JSON output (progress indicators, etc.) before the actual JSON array
        // This is a workaround for https://github.com/homebrew/brew/issues/20978
        // Since users may not upgrade Homebrew frequently, this fix will remain
        let jsonString = brewPhpAlias
            .components(separatedBy: .newlines)
            .drop(while: { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("[") })
            .joined(separator: "\n")

        // Get all packages
        let packages = try? JSONDecoder().decode(
            [HomebrewPackage].self,
            from: jsonString.data(using: .utf8)!
        )

        // But we only need the first one!
        guard let package = packages?.first else {
            Log.err("Could not determine PHP version due to malformed output.")
            return
        }

        self.homebrewPackage = package
    }

    /**
     Determine which PHP version the `php` formula is aliased to.
     */
    func determinePhpAlias() async {
        if let alias = self.homebrewPackage.version {
            PhpEnvironments.brewPhpAlias = self.homebrewPackage.version
            Log.info("[BREW] On your system, the `php` formula means version \(alias).")
        } else {
            Log.info("[BREW] Could not determine what version the `php` formula is. The alias may have been removed.")
            return
        }

        // Check if that version actually corresponds to an older version
        let phpConfigExecutablePath = "\(container.paths.optPath)/php/bin/php-config"
        if container.filesystem.fileExists(phpConfigExecutablePath) {
            let longVersionString = container.command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"],
                trimNewlines: false
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            if let version = try? VersionNumber.parse(longVersionString) {
                PhpEnvironments.brewPhpAlias = version.short
                if version.short != homebrewPackage.version {
                    Log.info("[BREW] An older or newer version of `php` is actually installed (\(version.short)).")
                }
            } else {
                Log.warn("Could not determine the actual version of the php binary; assuming Homebrew is correct.")
                PhpEnvironments.brewPhpAlias = homebrewPackage.version
            }
        }
    }

    // MARK: - Properties

    /** The delegate that is informed of updates. */
    weak var delegate: PhpSwitcherDelegate?

    /** Whether the switcher is busy performing any actions. */
    @MainActor var isBusy: Bool = false {
        didSet {
            MainMenu.shared.refreshIcon()
            MainMenu.shared.rebuild()
        }
    }

    // MARK: - Thread-Safe PHP Version Storage

    /** All versions of PHP that are currently supported. */
    private let _availablePhpVersions = Locked<[String]>([])
    var availablePhpVersions: [String] {
        get { _availablePhpVersions.value }
        set { _availablePhpVersions.value = newValue }
    }

    /** All versions of PHP that are currently installed but not compatible. */
    private let _incompatiblePhpVersions = Locked<[String]>([])
    var incompatiblePhpVersions: [String] {
        get { _incompatiblePhpVersions.value }
        set { _incompatiblePhpVersions.value = newValue }
    }

    /** Cached information about the PHP installations. */
    private let _cachedPhpInstallations = Locked<[String: PhpInstallation]>([:])
    var cachedPhpInstallations: [String: PhpInstallation] {
        get { _cachedPhpInstallations.value }
        set { _cachedPhpInstallations.value = newValue }
    }

    /** Information about the currently linked PHP installation. */
    private let _currentInstall = Locked<ActivePhpInstallation?>(nil)
    var currentInstall: ActivePhpInstallation? {
        get { _currentInstall.value }
        set {
            // Update the synchronized value
            _currentInstall.value = newValue
            // Let the PHP extension manager, if it exists, know the version changed
            App.shared.phpExtensionManagerWindowController?.view.didUpdatePhpVersion()
        }
    }

    /**
     The version that the `php` formula via Brew is aliased to on the current system.
     
     If you're up to date, `php` will be aliased to the latest version,
     but that might not be the case since not everyone keeps their
     software up-to-date.
     
     As such, we take that information from Homebrew.
     */
    static var brewPhpAlias: String?

    /**
     It's possible for the alias to be newer than the actual installed version of PHP.
     */
    var homebrewBrewPhpAlias: String? {
        if homebrewPackage == nil {
            // For UI testing and as a fallback, determine this version by using (fake) php-config
            let version = App.shared.container.command.execute(path: "/opt/homebrew/bin/php-config",
                                   arguments: ["--version"],
                                   trimNewlines: true)
            return try! VersionNumber.parse(version).short
        }

        return homebrewPackage.version
    }

    /**
     The currently linked and active PHP installation.
     */
    var phpInstall: ActivePhpInstallation? {
        return currentInstall
    }

    /**
     The most recent and stable PHP version available.
     Used when the Homebrew PHP alias could not be determined.
     */
    var fallbackPhpVersion: String {
        let stableVersion = container.phpEnvs.cachedPhpInstallations.first { (_: String, value: PhpInstallation) in
            return value.isPreRelease == false
        }

        if let stableVersion {
            return stableVersion.value.versionNumber.short
        } else {
            guard let unstableVersion = container.phpEnvs.cachedPhpInstallations.first else {
                fatalError("Could not find a valid PHP version to fallback to. None are installed?")
            }
            return unstableVersion.value.versionNumber.short
        }
    }

    /**
     Information we were able to discern from the Homebrew info command.
     */
    var homebrewPackage: HomebrewPackage! = nil

    // MARK: - Methods

    /**
     The switcher that is currently in use.
     This was originally added so the Internal and Valet switcher could be swapped out,
     but currently this is no longer needed.
     */
    public static var switcher: PhpSwitcher {
        return InternalSwitcher(App.shared.container)
    }

    public func reloadPhpVersions() async {
        _ = await self.detectPhpVersions()
    }

    /**
     Detects which versions of PHP are installed.
     This step also detects which versions of PHP are incompatible with the current version of Valet.
     If a PHP installation is currently broken, that will also be reflected.

     Returns a `Set<String>` of installations that are considered valid.
     */
    public func detectPhpVersions() async -> Set<String> {
        let files = await container.shell.pipe("ls \(container.paths.optPath) | grep php@").out

        let versions = await extractPhpVersions(from: files.components(separatedBy: "\n"))

        let supportedByValet: Set<String> = {
            guard let version = Valet.shared.version else {
                return Constants.DetectedPhpVersions
            }

            return Constants.ValetSupportedPhpVersionMatrix[version.major] ?? []
        }()

        var supportedVersions = Valet.installed ? versions.intersection(supportedByValet) : versions

        // Make sure the aliased version is detected
        // The user may have `php` installed, but not e.g. `php@8.0`
        // We should also detect that as a version that is installed
        if let phpAlias = homebrewPackage.version {
            // Avoid inserting a duplicate
            if !supportedVersions.contains(phpAlias) && container.filesystem.fileExists("\(container.paths.optPath)/php/bin/php") {
                let phpAliasInstall = PhpInstallation(container, phpAlias)
                // Before inserting, ensure that the actual output matches the alias
                // if that isn't the case, our formula remains out-of-date
                if !phpAliasInstall.isMissingBinary {
                    supportedVersions.insert(phpAlias)
                }
            }
        }

        availablePhpVersions = Array(supportedVersions)
            .sorted(by: { $0.versionCompare($1) == .orderedDescending })

        incompatiblePhpVersions = Array(versions.subtracting(supportedByValet))
            .sorted(by: { $0.versionCompare($1) == .orderedDescending })

        Log.info("The PHP versions that were detected are: \(availablePhpVersions)")
        Log.info("The PHP versions that were unsupported are: \(incompatiblePhpVersions)")

        var mappedVersions: [String: PhpInstallation] = [:]

        availablePhpVersions.forEach { version in
            mappedVersions[version] = PhpInstallation(container, version)
        }

        cachedPhpInstallations = mappedVersions

        return supportedVersions
    }

    /**
     Extracts valid PHP versions from an array of strings.
     This array of strings is usually retrieved from `grep`.
     
     If `generateHelpers` is set to true, after detecting
     all versions, helper scripts are generated as well.
     */
    public func extractPhpVersions(
        from versions: [String],
        checkBinaries: Bool = true,
        generateHelpers: Bool = true
    ) async -> Set<String> {
        let supported = Constants.DetectedPhpVersions
        var output: Set<String> = []
        versions.filter { (version) -> Bool in
            // Omit everything that doesn't start with php@
            // (e.g. something-php@8.0 won't be detected)
            return version.starts(with: "php@")
        }.forEach { (string) in
            let version = string.components(separatedBy: "php@")[1]
            // Only append the version if it doesn't already exist (avoid dupes),
            // is supported and where the binary exists (avoids broken installs)
            if !output.contains(version)
                && supported.contains(version)
                && (checkBinaries ? container.filesystem.fileExists("\(container.paths.optPath)/php@\(version)/bin/php") : true) {
                output.insert(version)
            }
        }

        if generateHelpers {
            for item in output {
                await PhpHelper.generate(container, for: item)
            }
        }

        return output
    }

    /**
     Returns a list of `VersionNumber` instances based on the available PHP versions
     that are valid to switch to for a given constraint.
     */
    public func validVersions(for constraint: String) -> [VersionNumber] {
        constraint.split(separator: "|").flatMap {
            return PhpVersionNumberCollection
                .make(from: self.availablePhpVersions)
                .matching(constraint: $0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /**
     Validates whether the currently running version matches the provided version.
     */
    public func validate(_ version: String) -> Bool {
        guard let install = self.phpInstall else {
            Log.info("It appears as if no PHP installation is currently active.")
            return false
        }

        if install.version.short == version {
            Log.info("Switching to version \(version) seems to have succeeded. Validation passed.")
            Log.info("Keeping track that this is the new version!")
            Stats.persistCurrentGlobalPhpVersion(version: version)

            return true
        }

        return false
    }

    /**
     Returns the configuration file instance that is used for a specific config value.
     You can then use the configuration file instance to change values.
     */
    public func getConfigFile(forKey key: String) -> PhpConfigurationFile? {
        guard let install = self.phpInstall else {
            return nil
        }

        return install.iniFiles
            .reversed()
            .first(where: { $0.has(key: key) })
    }
}
