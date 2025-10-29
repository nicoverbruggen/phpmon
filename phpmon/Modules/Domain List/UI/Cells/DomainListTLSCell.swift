//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit
import SwiftUI

class DomainListTLSCell: NSTableCellView, DomainListCellProtocol {
    var domain: ValetListable?

    @IBOutlet weak var buttonLockStatus: NSButton!
    @IBOutlet weak var imageViewLock: NSImageView!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListTLSCell"
    }

    func populateCell(with site: ValetSite) {
        domain = site

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

    var container: Container {
        return App.shared.container
    }

    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.domain else { return }

        let button = self.buttonLockStatus!
        let popover = NSPopover()

        let view = SecurePopoverView(
            name: site.getListableName(),
            tld: Valet.shared.config.tld,
            expires: site.getListableCertificateExpiryDate()
        )

        let controller = NSHostingController(rootView: view)

        // Force a layout pass to get accurate sizing, this resolves positioning issues
        controller.view.setFrameSize(NSSize(width: 300, height: 1000))
        controller.view.layoutSubtreeIfNeeded()

        let fittingSize = controller.view.fittingSize
        let finalWidth: CGFloat = min(fittingSize.width, 300)

        controller.view.frame = NSRect(x: 0, y: 0, width: finalWidth, height: fittingSize.height)

        popover.contentViewController = controller
        popover.behavior = .transient
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }
}
