//
//  SiteListTypeCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListKindCell: NSTableCellView, SiteListCellProtocol
{
    @IBOutlet weak var imageViewType: NSImageView!
    
    func populateCell(with site: ValetSite) {
        
        // If the `aliasPath` is nil, we're dealing with a parked site (otherwise: linked).
        imageViewType.image = NSImage(
            named: site.aliasPath == nil
            ? "IconParked"
            : "IconLinked"
        )
        
        imageViewType.contentTintColor = NSColor.tertiaryLabelColor
    }
}
