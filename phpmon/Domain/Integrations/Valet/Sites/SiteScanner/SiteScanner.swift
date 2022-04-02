//
//  ValetSiteScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol SiteScanner
{
    func resolveSiteCount(paths: [String]) -> Int
    
    func resolveSitesFrom(paths: [String]) -> [ValetSite]
    
    func resolveSite(path: String) -> ValetSite?
}
