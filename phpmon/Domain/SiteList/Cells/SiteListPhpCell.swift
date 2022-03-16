//
//  SiteListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListPhpCell: NSTableCellView, SiteListCellProtocol
{
    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!
    
    func populateCell(with site: ValetSite) {
        let versionInUse = site.isolatedPhpVersion?.versionNumber.homebrewVersion ?? PhpEnv.phpInstall.version.short
        buttonPhpVersion.title = " PHP \(versionInUse)"
        
        if site.isolatedPhpVersion != nil {
            imageViewPhpVersionOK.isHidden = false
            imageViewPhpVersionOK.image = NSImage(named: "Isolated")
        } else {
            imageViewPhpVersionOK.isHidden = (site.composerPhp == "???" || !site.composerPhpCompatibleWithLinked)
            imageViewPhpVersionOK.image = NSImage(named: "Checkmark")
        }
        
        
    }
    
}
