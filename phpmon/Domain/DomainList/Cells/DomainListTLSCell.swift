//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListTLSCell: NSTableCellView, DomainListCellProtocol
{
    static let reusableName = "domainListTLSCell"
    
    @IBOutlet weak var imageViewLock: NSImageView!
    
    func populateCell(with site: ValetSite) {
        imageViewLock.contentTintColor = site.secured
            ? NSColor(named: "IconColorGreen")
            : NSColor(named: "IconColorRed")
    }
    
    func populateCell(with proxy: ValetProxy) {
        imageViewLock.contentTintColor = proxy.target.contains("https")
            ? NSColor(named: "IconColorGreen")
            : NSColor(named: "IconColorRed")
    }
}
