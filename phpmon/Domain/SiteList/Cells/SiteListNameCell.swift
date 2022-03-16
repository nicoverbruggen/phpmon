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
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!
    
    func populateCell(with site: ValetSite) {
        // Show the name of the site (including tld)
        labelSiteName.stringValue = "\(site.name).\(Valet.shared.config.tld)"

        // Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        labelPathName.stringValue = site.absolutePathRelative
    }
}
