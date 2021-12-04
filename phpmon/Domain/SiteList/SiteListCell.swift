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
    @IBOutlet weak var labelPhpVersion: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
