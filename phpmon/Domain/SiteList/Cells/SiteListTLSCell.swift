//
//  SiteListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListTLSCell: NSTableCellView, SiteListCellProtocol
{
    var site: ValetSite? = nil
    
    @IBOutlet weak var imageViewLock: NSImageView!
    
    func populateCell(with site: ValetSite) {
        self.site = site
        
        // Show the green or red lock based on whether the site was secured
        imageViewLock.contentTintColor = site.secured
            ? NSColor(named: "IconColorGreen") // green
            : NSColor(named: "IconColorRed")
    }
}
