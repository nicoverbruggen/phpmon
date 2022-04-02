//
//  ValetSiteScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetSiteScanner: SiteScanner
{
    func resolveSiteCount(paths: [String]) -> Int {
        return paths.map { path in
            
            let entries = try! FileManager.default
                .contentsOfDirectory(atPath: path)
            
            return entries
                .map { self.isSite($0, forPath: path) }
                .filter{ $0 == true}
                .count
            
        }.reduce(0, +)
    }
    
    func resolveSitesFrom(paths: [String]) -> [ValetSite] {
        var sites: [ValetSite] = []
        
        paths.forEach { path in
            let entries = try! FileManager.default
                .contentsOfDirectory(atPath: path)
            
            return entries.forEach {
                if let site = self.resolveSite(path: "\(path)/\($0)") {
                    sites.append(site)
                }
            }
        }
        
        return sites
    }
    
    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored, and the site is added to Valet's list of sites.
     */
    func resolveSite(path: String) -> ValetSite? {
        // Get the TLD from the global Valet object
        let tld = Valet.shared.config.tld
        
        // See if the file is a symlink, if so, resolve it
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            Log.warn("Could not parse the site: \(path), skipping!")
            return nil
        }
        
        // We can also determine whether the thing at the path is a directory, too
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        // We should also check that we can interpret the path correctly
        if URL(fileURLWithPath: path).lastPathComponent == "" {
            Log.warn("Could not parse the site: \(path), skipping!")
            return nil
        }
        
        if type == FileAttributeType.typeSymbolicLink {
            return ValetSite(aliasPath: path, tld: tld)
        } else if type == FileAttributeType.typeDirectory {
            return ValetSite(absolutePath: path, tld: tld)
        }
        
        return nil
    }
    
    /**
     Determines whether the site can be resolved as a symbolic link or as a directory.
     Regular files are ignored. Returns true if the path can be parsed.
     */
    private func isSite(_ entry: String, forPath path: String) -> Bool {
        let siteDir = path + "/" + entry
        
        let attrs = try! FileManager.default.attributesOfItem(atPath: siteDir)
        
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        if type == FileAttributeType.typeSymbolicLink || type == FileAttributeType.typeDirectory {
            return true
        }
        
        return false
    }
}
