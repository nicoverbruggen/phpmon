//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class Valet {

    enum FeatureFlag {
        case isolatedSites,
             supportForPhp56
    }

    static let shared = Valet()

    /// The version of Valet that was detected.
    var version: String! = nil

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
            ValetScanners.useFake()
        }
    }

    /**
     Check if a particular feature is enabled.
     */
    public static func enabled(feature: FeatureFlag) -> Bool {
        return self.shared.features.contains(feature)
    }

    /**
     Retrieve a list of all domains, including sites & proxies.
     */
    public static func getDomainListable() -> [DomainListable] {
        return self.shared.sites + self.shared.proxies
    }

    /**
     Notify the user about a non-default TLD being set.
     */
    public static func notifyAboutUnsupportedTLD() {
        if Valet.shared.config.tld != "test" && Preferences.isEnabled(.warnAboutNonStandardTLD) {
            Task { @MainActor in
                BetterAlert().withInformation(
                    title: "alert.warnings.tld_issue.title".localized,
                    subtitle: "alert.warnings.tld_issue.subtitle".localized,
                    description: "alert.warnings.tld_issue.description".localized
                )
                .withPrimary(text: "OK")
                .withTertiary(text: "alert.do_not_tell_again".localized, action: { alert in
                    Preferences.update(.warnAboutNonStandardTLD, value: false)
                    alert.close(with: .alertThirdButtonReturn)
                })
                .show()
            }
        }
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
                from: FileSystem.readStringFromFile("~/.config/valet/config.json").data(using: .utf8)!
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
        let isOlderThanVersionThree = version.versionCompare("3.0") == .orderedAscending

        if isOlderThanVersionThree {
            self.features.append(.supportForPhp56)
        } else {
            Log.info("This version of Valet supports isolation.")
            self.features.append(.isolatedSites)
        }
    }

    /**
     Checks if the version of Valet is more recent than the minimum version required for PHP Monitor to function.
     Should this procedure fail, the user will get an alert notifying them that the version of Valet they have
     installed is not recent enough.
     */
    public func validateVersion() {
        // 1. Evaluate feature support
        Valet.shared.evaluateFeatureSupport()

        // 2. Notify user if the version is too old
        if version.versionCompare(Constants.MinimumRecommendedValetVersion) == .orderedAscending {
            let version = version
            Log.warn("Valet version \(version!) is too old! (recommended: \(Constants.MinimumRecommendedValetVersion))")
            Task { @MainActor in
                BetterAlert()
                    .withInformation(
                        title: "alert.min_valet_version.title".localized,
                        subtitle: "alert.min_valet_version.info".localized(
                            version!,
                            Constants.MinimumRecommendedValetVersion
                        )
                    )
                    .withPrimary(text: "OK")
                    .show()
            }
        } else {
            Log.info("Valet version \(version!) is recent enough, OK " +
                     "(recommended: \(Constants.MinimumRecommendedValetVersion))")
        }
    }

    public func hasPlatformIssues() async -> Bool {
        return await Shell.pipe("valet --version")
            .out.contains("Composer detected issues in your platform")
    }

    /**
     Returns a count of how many sites are linked and parked.
     */
    private func countPaths() -> Int {
        return ValetScanners.siteScanner
            .resolveSiteCount(paths: config.paths)
    }

    /**
     Resolves all paths and creates linked or parked site instances that can be referenced later.
     */
    private func resolvePaths() {
        isBusy = true

        sites = ValetScanners.siteScanner
            .resolveSitesFrom(paths: config.paths)
            .sorted {
                $0.absolutePath < $1.absolutePath
            }

        proxies = ValetScanners.proxyScanner
            .resolveProxies(
                directoryPath: FileManager.default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent(".config/valet/Nginx")
                    .path
            )

        if let defaultPath = Valet.shared.config.defaultSite,
            let site = ValetSiteScanner().resolveSite(path: defaultPath) {
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
