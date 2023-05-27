//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 This class is responsible for handling the state of Valet throughout PHP Monitor. A singleton instance is created
 and accessible throughout the lifecycle of the app, unless the user has decided to not use Valet. In that case,
 only a restricted subset of functionality is available in the app.
 */
class Valet {

    enum FeatureFlag {
        case isolatedSites
    }

    static let shared = Valet()

    /// The version of Valet that was detected.
    var version: VersionNumber?

    /// The Valet configuration file.
    var config: Valet.Configuration!

    /// A cached list of sites that were detected after analyzing the paths set up for Valet.
    var sites: [ValetSite] = []

    /// A cached list of proxies that were detecting after analyzing the Nginx paths.
    var proxies: [ValetProxy] = []

    /// Whether we're busy with some blocking operation.
    var isBusy: Bool = false

    /// Various feature flags. Enabled based on the installed Valet version.
    var features: [FeatureFlag] = []

    /// When initialising the Valet singleton, assume no sites or proxies loaded.
    /// We will load the version later.
    init() {
        self.version = nil
        self.sites = []
        self.proxies = []
        self.checkForMarketingMode()
    }

    /// If marketing mode is enabled, you can tinker around with the site list
    /// without actually modifying items on your local system.
    public func checkForMarketingMode() {
        if ProcessInfo.processInfo.environment["PHPMON_MARKETING_MODE"] != nil {
            Log.info("Using a fake list of sites for Marketing Mode!")
            ValetScanner.useFake()
        }
    }

    static var installed: Bool {
        return self.shared.installed
    }

    lazy var installed: Bool = {
        return FileSystem.fileExists(Paths.binPath.appending("/valet"))
            && FileSystem.anyExists("~/.config/valet")
    }()

    /**
     Check if a particular feature is enabled.
     */
    public static func enabled(feature: FeatureFlag) -> Bool {
        return self.shared.features.contains(feature)
    }

    /**
     Retrieve a list of all domains, including sites & proxies.
     */
    public static func getDomainListable() -> [ValetListable] {
        return self.shared.sites + self.shared.proxies
    }

    /**
     We don't want to load the initial config.json file as soon as the class is initialised.
     
     Instead, we'll defer the loading of the configuration file once the initial app checks
     have passed: otherwise the file might not exist, leading to a crash.
     
     Since version 5.2, it is no longer possible for an invalid file to crash the app.
     If the JSON is invalid when the app launches, an alert will be presented, however.
     */
    public func loadConfiguration() {
        do {
            config = try JSONDecoder().decode(
                Valet.Configuration.self,
                from: FileSystem.getStringFromFile("~/.config/valet/config.json").data(using: .utf8)!
            )
        } catch {
            Log.err(error)
        }
    }

    /**
     Starts the preload of sites. In order to make sure PHP Monitor can correctly
     handle all PHP versions including isolation, it needs to know about all sites.
     */
    public func startPreloadingSites() async {
        await self.reloadSites()
    }

    /**
     Reloads the list of sites, assuming that the list isn't being reloaded at the time.
     (We don't want to do duplicate or parallel work!)
     */
    public func reloadSites() async {
        loadConfiguration()

        if isBusy {
            return
        }

        resolvePaths()
    }

    /**
     Depending on the version of Valet that is active, the feature set of PHP Monitor will change.
     
     In version 6.0, support for Valet 2.x will be dropped, but until then features are evaluated by using the helper
     `enabled(feature)`, which contains information about the feature set of the version of Valet that is currently
     in use. This allows PHP Monitor to do different things when Valet 3.0 is enabled.
     */
    public func evaluateFeatureSupport() {
        guard let version = self.version else {
            Log.err("Cannot determine features, as the version was not determined.")
            return
        }

        switch version.major {
        case 2:
            Log.info("You are running Valet v2. Support for site isolation is disabled.")
        case 3, 4:
            Log.info("You are running Valet v\(version.major). Support for site isolation is available.")
            self.features.append(.isolatedSites)
        default:
            Log.err("This version of Valet is not supported.")
        }
    }

    /**
     Checks if the version of Valet is more recent than the minimum version required for PHP Monitor to function.
     Should this procedure fail, the user will get an alert notifying them that the version of Valet they have
     installed is not recent enough.
     */
    public func validateVersion() {
        guard let version = self.version else {
            Log.err("Cannot validate Valet version if no Valet version was determined.")
            return
        }

        if PhpEnvironments.phpInstall == nil {
            Log.info("Cannot validate Valet version if no PHP version is linked.")
            return
        }

        // 1. Evaluate feature support
        Valet.shared.evaluateFeatureSupport()

        // 2. Notify user if the version is too old (but major version is OK)
        if version.text.versionCompare(Constants.MinimumRecommendedValetVersion) == .orderedAscending {
            let recommended = Constants.MinimumRecommendedValetVersion
            Log.warn("Valet version \(version.text) is too old! (recommended: \(recommended))")
            self.notifyAboutOutdatedValetVersion(version)
        } else {
            Log.info("Valet version \(version.text) is recent enough, OK " +
                     "(recommended: \(Constants.MinimumRecommendedValetVersion))")
        }
    }

    /**
     Determine if any platform issues are detected when running `valet --version`.
     */
    public func hasPlatformIssues() async -> Bool {
        return await Shell.pipe("valet --version")
            .out.contains("Composer detected issues in your platform")
    }

    /**
     Determine if PHP-FPM is configured correctly.

     For PHP 5.6, we'll check if `valet.sock` is included in the main `php-fpm.conf` file, but for more recent
     versions of PHP, we can just check for the existence of the `valet-fpm.conf` file. If the check here fails,
     that means that Valet won't work properly.
     */
    func phpFpmConfigurationValid() async -> Bool {
        guard let version = PhpEnvironments.shared.currentInstall?.version else {
            Log.info("Cannot check PHP-FPM status: no version of PHP is active")
            return true
        }

        if version.short == "5.6" {
            // The main PHP config file should contain `valet.sock` and then we're probably fine?
            let fileName = "\(Paths.etcPath)/php/5.6/php-fpm.conf"
            return await Shell.pipe("cat \(fileName)").out
                .contains("valet.sock")
        }

        // Make sure to check if valet-fpm.conf exists. If it does, we should be fine :)
        return FileSystem.fileExists("\(Paths.etcPath)/php/\(version.short)/php-fpm.d/valet-fpm.conf")
    }

    /**
     Returns a count of how many sites are linked and parked.
     */
    private func countPaths() -> Int {
        return ValetScanner.active.resolveSiteCount(paths: config.paths)
    }

    /**
     Resolves all paths and creates linked or parked site instances that can be referenced later.
     */
    private func resolvePaths() {
        isBusy = true

        sites = ValetScanner.active
            .resolveSitesFrom(paths: config.paths)
            .sorted {
                $0.absolutePath < $1.absolutePath
            }

        proxies = ValetScanner.active
            .resolveProxies(
                directoryPath: "~/.config/valet/Nginx".replacingTildeWithHomeDirectory
            )

        if let defaultPath = Valet.shared.config.defaultSite,
           let site = ValetScanner.active.resolveSite(path: defaultPath) {
            sites.insert(site, at: 0)
        }

        Log.info("\(sites.count) sites & \(proxies.count) proxies have been scanned.")

        isBusy = false
    }

    struct Configuration: Decodable {
        /// Top level domain suffix. Usually "test" but can be set to something else.
        /// - Important: Does not include the actual dot. ("test", not ".test"!)
        let tld: String

        /// The paths that need to be checked.
        let paths: [String]

        /// The loopback address. Optional.
        let loopback: String?

        /// The default site that is served if the domain is not found. Optional.
        let defaultSite: String?

        // swiftlint:disable nesting
        private enum CodingKeys: String, CodingKey {
            case tld, paths, loopback, defaultSite = "default"
        }
        // swiftlint:enable nesting
    }

}
