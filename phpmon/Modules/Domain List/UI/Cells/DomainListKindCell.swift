//
//  DomainListTypeCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListKindCell: NSTableCellView, DomainListCellProtocol {
    static let reusableName = "domainListKindCell"

    @IBOutlet weak var imageViewType: NSImageView!

    func populateCell(with site: ValetSite) {
        // If the `aliasPath` is nil, we're dealing with a parked site (otherwise: linked).
        imageViewType.image = site.aliasPath == nil
            ? NSImage.iconParked
            : NSImage.iconLinked

        // Unless, of course, this is a default site
        if site.absolutePath == Valet.shared.config.defaultSite {
            imageViewType.image = NSImage.iconDefault
        }

        imageViewType.contentTintColor = NSColor.tertiaryLabelColor
    }

    func populateCell(with proxy: ValetProxy) {
        imageViewType.image = NSImage.iconProxy
    }
}
