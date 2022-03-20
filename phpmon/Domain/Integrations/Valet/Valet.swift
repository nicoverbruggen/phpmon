//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
    
    /// Whether we're busy with some blocking operation.
    var isBusy: Bool = false
    
    /// Various feature flags. Enabled based on the installed Valet version.
    var features: [FeatureFlag] = []
    
    /// When initialising the Valet singleton assume no sites loaded. We will load the version later.
    init() {
        self.version = nil
        self.sites = []
    }
    
    /**
     If marketing mode is enabled, show a list of sites that are used for promotional screenshots.
     This can be done by swapping out the real Valet scanner with one that always returns a fixed
     list of fake sites. You should not interact with these sites!
     */
    static var siteScanner: SiteScanner {
        if ProcessInfo.processInfo.environment["PHPMON_MARKETING_MODE"] != nil {
            return FakeSiteScanner()
        }
        
        return ValetSiteScanner()
    }
    
    /**
     Check if a particular feature is enabled.
     */
    public static func enabled(feature: FeatureFlag) -> Bool {
        return self.shared.features.contains(feature)
    }
    
    /**
     We don't want to load the initial config.json file as soon as the class is initialised.
     Instead, we'll defer the loading of the configuration file once the initial app checks
     have passed: if the user does not have Valet installed, we'll crash the app because we
     force unwrap the file. Currently, this does also mean that if the JSON is invalid or
     incompatible with the `Decodable` `Valet.Configuration` class, that the app will crash.
     */
    public func loadConfiguration() {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/valet/config.json")
        
        do {
            config = try JSONDecoder().decode(
                Valet.Configuration.self,
                from: try String(contentsOf: file, encoding: .utf8).data(using: .utf8)!
            )
        } catch {
            Log.err(error)
        }
    }
    
    /**
     Starts the preload of sites, but only if the maximum amount of sites is 30.
     For users with more sites, the site list is loaded when they bring up the site list window.
     (This is done to keep the startup speed as fast as possible.)
     */
    public func startPreloadingSites() {
        let maximumPreload = 30
        let foundSites = self.countPaths()
        if foundSites <= maximumPreload {
            // Preload the sites and their drivers
            Log.info("Fewer than or \(maximumPreload) sites found, preloading list of sites...")
            self.reloadSites()
        } else {
            Log.info("\(foundSites) sites found, exceeds \(maximumPreload) for preload at launch!")
        }
    }
    
    /**
     Reloads the list of sites, assuming that the list isn't being reloaded at the time.
     We don't want to do duplicate or parallel work!
     */
    public func reloadSites() {
        loadConfiguration()
        
        if (isBusy) {
            return
        }
        
        resolvePaths()
    }
    
    /**
     Checks if the version of Valet is more recent than the minimum version required for PHP Monitor to function.
     Should this procedure fail, the user will get an alert notifying them that the version of Valet they have
     installed is not recent enough.
     */
    public func validateVersion() -> Void {
        if Shell.pipe("valet", requiresPath: true).contains("isolate") {
            Log.info("This version of Valet supports isolation.")
            self.features.append(.isolatedSites)
        }
        
        if version.versionCompare("3.0") == .orderedAscending {
            self.features.append(.supportForPhp56)
        }
        
        if version.versionCompare(Constants.MinimumRecommendedValetVersion) == .orderedAscending {
            let version = version
            Log.warn("Valet version \(version!) is too old! (recommended: \(Constants.MinimumRecommendedValetVersion))")
            DispatchQueue.main.async {
                BetterAlert()
                    .withInformation(
                        title: "alert.min_valet_version.title".localized,
                        subtitle:"alert.min_valet_version.info".localized(version!, Constants.MinimumRecommendedValetVersion)
                    )
                    .withPrimary(text: "OK")
                    .show()
            }
        } else {
            Log.info("Valet version \(version!) is recent enough, OK (recommended: \(Constants.MinimumRecommendedValetVersion))")
        }
    }
    
    /**
     Returns a count of how many sites are linked and parked.
     */
    private func countPaths() -> Int {
        return Self.siteScanner
            .resolveSiteCount(paths: config.paths)
    }
    
    /**
     Resolves all paths and creates linked or parked site instances that can be referenced later.
     */
    private func resolvePaths() {
        isBusy = true
        
        sites = Self.siteScanner
            .resolveSitesFrom(paths: config.paths)
            .sorted { $0.absolutePath < $1.absolutePath }
        
        if let defaultPath = Valet.shared.config.defaultSite,
            let site = ValetSiteScanner().resolveSite(path: defaultPath) {
            sites.insert(site, at: 0)
        }
        
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
        
        private enum CodingKeys: String, CodingKey {
            case tld, paths, loopback, defaultSite = "default"
        }
    }
    
}
