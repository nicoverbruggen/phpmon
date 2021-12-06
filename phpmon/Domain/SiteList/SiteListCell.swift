//
//  SiteListCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListCell: NSTableCellView
{
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!
    
    @IBOutlet weak var imageViewLock: NSImageView!
    @IBOutlet weak var imageViewType: NSImageView!
    
    @IBOutlet weak var labelDriver: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func populateCell(with site: Valet.Site) {
        // Make sure to show the TLD
        labelSiteName.stringValue = "\(site.name!).\(Valet.shared.config.tld)"
        
        // Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        labelPathName.stringValue = site.absolutePath
            .replacingOccurrences(of: "/Users/\(Paths.whoami)", with: "~")
        
        // If the `aliasPath` is nil, we're dealing with a parked site (otherwise: linked).
        imageViewType.image = NSImage(
            named: site.aliasPath == nil
            ? "IconParked"
            : "IconLinked"
        )
        imageViewType.contentTintColor = NSColor.tertiaryLabelColor
        
        // Show the green or red lock based on whether the site was secured
        imageViewLock.contentTintColor = site.secured ? NSColor.systemGreen
        : NSColor.red
        
        // Show the current driver
        labelDriver.stringValue = site.driver ?? "???"
    }
}
