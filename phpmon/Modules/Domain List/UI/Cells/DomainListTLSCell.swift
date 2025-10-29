//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListTLSCell: NSTableCellView, DomainListCellProtocol {
    @IBOutlet weak var imageViewLock: NSImageView!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListTLSCell"
    }

    func populateCell(with site: ValetSite) {
        imageViewLock.image = NSImage(named: site.secured ? "Lock" : "LockUnlocked")!

        imageViewLock.contentTintColor = site.secured
            ? nil
            : NSColor(named: "IconColorRed")

        if site.secured && site.isCertificateExpired {
            imageViewLock.contentTintColor = NSColor(named: "StatusColorOrange")
        }
    }

    func populateCell(with proxy: ValetProxy) {
        imageViewLock.image = NSImage(named: proxy.secured ? "Lock" : "LockUnlocked")!
        imageViewLock.contentTintColor = proxy.secured
            ? nil
            : NSColor(named: "IconColorRed")

        if proxy.secured && proxy.isCertificateExpired {
            imageViewLock.contentTintColor = NSColor(named: "StatusColorOrange")
        }
    }
}
