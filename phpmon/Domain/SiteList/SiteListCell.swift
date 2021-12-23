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
    
    @IBOutlet weak var buttonWarning: NSButton!
    @IBOutlet weak var labelWarning: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func populateCell(with site: Valet.Site) {
        // Make sure to show the TLD
        labelSiteName.stringValue = "\(site.name!).\(Valet.shared.config.tld)"
        
        let isProblematic = site.name.contains(" ")
        buttonWarning.isHidden = !isProblematic
        labelWarning.isHidden = !isProblematic
        labelWarning.stringValue = "site_list.warning.spaces".localized
        
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
        imageViewLock.image = NSImage(named: site.secured ? "Lock" : "LockUnlocked")
        imageViewLock.contentTintColor = site.secured ?
            NSColor.init(red: 63/255, green: 195/255, blue: 128/255, alpha: 1.0) // green
            : NSColor.init(red: 246/255, green: 71/255, blue: 71/255, alpha: 1.0) // red
        
        // Show the current driver
        labelDriver.stringValue = site.driver ?? "???"
    }
}
