//
//  SiteListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListNameCell: NSTableCellView, SiteListCellProtocol
{
    var site: ValetSite? = nil
    
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!
    
    func populateCell(with site: ValetSite) {
        self.site = site
        
        var siteName = "\(site.name).\(Valet.shared.config.tld)"

        labelSiteName.stringValue = siteName
        
        // Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        labelPathName.stringValue = site.absolutePathRelative
    }
}
