//
//  PhpEnvironments.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpEnvironments {
    var container: Container

    // MARK: - Initializer

    /**
     Loads the currently active PHP installation upon startup. May be empty.
     */
    init(container: Container = App.shared.container) {
        self.container = container
        self.currentInstall = ActivePhpInstallation.load()
    }

    /**
     Creates the shared instance. Called when starting the app.
     */
    static func prepare() {
        _ = Self.shared
    }

    /**
     Determine which PHP version the `php` formula is aliased to.
     */
    @MainActor func determinePhpAlias() async {
        let brewPhpAlias = await container.shell.pipe("\(Paths.brew) info php --json").out

        self.homebrewPackage = try! JSONDecoder().decode(
            [HomebrewPackage].self,
            from: brewPhpAlias.data(using: .utf8)!
        ).first!

        PhpEnvironments.brewPhpAlias = self.homebrewPackage.version
        Log.info("[BREW] On your system, the `php` formula means version \(homebrewPackage.version).")

        // Check if that version actually corresponds to an older version
        let phpConfigExecutablePath = "\(Paths.optPath)/php/bin/php-config"
        if FileSystem.fileExists(phpConfigExecutablePath) {
            let longVersionString = Command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"],
                trimNewlines: false
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            if let version = try? VersionNumber.parse(longVersionString) {
                PhpEnvironments.brewPhpAlias = version.short
                if version.short != homebrewPackage.version {
                    Log.info("[BREW] An older version of `php` is actually installed (\(version.short)).")
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

    /** The static instance. Accessible at any time. */
    static let shared = PhpEnvironments()

    /** Whether the switcher is busy performing any actions. */
    @MainActor var isBusy: Bool = false {
        didSet {
            MainMenu.shared.refreshIcon()
            MainMenu.shared.rebuild()
        }
    }

    /** All versions of PHP that are currently supported. */
    var availablePhpVersions: [String] = []

    /** All versions of PHP that are currently installed but not compatible. */
    var incompatiblePhpVersions: [String] = []

    /** Cached information about the PHP installations. */
    var cachedPhpInstallations: [String: PhpInstallation] = [:]

    /** Information about the currently linked PHP installation. */
    var currentInstall: ActivePhpInstallation? {
        didSet {
            // Let the PHP extension manager, if it exists, know the version changed
            if let version = currentInstall?.version.short {
                App.shared.phpExtensionManagerWindowController?.view?.manager.phpVersion = version
            }
        }
    }

    /**
     The version that the `php` formula via Brew is aliased to on the current system.
     
     If you're up to date, `php` will be aliased to the latest version,
     but that might not be the case since not everyone keeps their
     software up-to-date.
     
     As such, we take that information from Homebrew.
     */
    static var brewPhpAlias: String = ""

    /**
     It's possible for the alias to be newer than the actual installed version of PHP.
     */
    static var homebrewBrewPhpAlias: String {
        if PhpEnvironments.shared.homebrewPackage == nil {
            // For UI testing and as a fallback, determine this version by using (fake) php-config
            let version = Command.execute(path: "/opt/homebrew/bin/php-config",
                                   arguments: ["--version"],
                                   trimNewlines: true)
            return try! VersionNumber.parse(version).short
        }

        return PhpEnvironments.shared.homebrewPackage.version
    }

    /**
     The currently linked and active PHP installation.
     */
    static var phpInstall: ActivePhpInstallation? {
        return Self.shared.currentInstall
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
        return InternalSwitcher()
    }

    /**
     Alias that detects which versions of PHP are installed.
     See also: `detectPhpVersions()`. Please note that this method
     does *not* return the set of PHP versions that are supported.
     */
    public static func detectPhpVersions() async {
        _ = await Self.shared.detectPhpVersions()
    }

    /**
     Detects which versions of PHP are installed.
     This step also detects which versions of PHP are incompatible with the current version of Valet.
     If a PHP installation is currently broken, that will also be reflected.

     Returns a `Set<String>` of installations that are considered valid.
     */
    public func detectPhpVersions() async -> Set<String> {
        let files = await container.shell.pipe("ls \(Paths.optPath) | grep php@").out

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
        let phpAlias = homebrewPackage.version

        // Avoid inserting a duplicate
        if !supportedVersions.contains(phpAlias) && FileSystem.fileExists("\(Paths.optPath)/php/bin/php") {
            let phpAliasInstall = PhpInstallation(phpAlias)
            // Before inserting, ensure that the actual output matches the alias
            // if that isn't the case, our formula remains out-of-date
            if !phpAliasInstall.isMissingBinary {
                supportedVersions.insert(phpAlias)
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
            mappedVersions[version] = PhpInstallation(version)
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
                && (checkBinaries ? FileSystem.fileExists("\(Paths.optPath)/php@\(version)/bin/php") : true) {
                output.insert(version)
            }
        }

        if generateHelpers {
            for item in output {
                await PhpHelper.generate(for: item)
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
        guard let install = PhpEnvironments.phpInstall else {
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
        guard let install = PhpEnvironments.phpInstall else {
            return nil
        }

        return install.iniFiles
            .reversed()
            .first(where: { $0.has(key: key) })
    }
}
