//
//  DomainListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit
import SwiftUI

class DomainListPhpCell: NSTableCellView, DomainListCellProtocol {
    var container: Container {
        return App.shared.container
    }

    var site: ValetSite?

    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListPhpCell"
    }

    func populateCell(with site: ValetSite) {
        self.site = site

        buttonPhpVersion.isHidden = false
        imageViewPhpVersionOK.isHidden = false

        buttonPhpVersion.title = " PHP \(site.servingPhpVersion)"

        imageViewPhpVersionOK.toolTip = nil

        imageViewPhpVersionOK.contentTintColor = site.isCompatibleWithPreferredPhpVersion
            ? NSColor(named: "IconColorGreen")
            : NSColor(named: "IconColorRed")

        if site.isolatedPhpVersion != nil {
            imageViewPhpVersionOK.isHidden = false
            imageViewPhpVersionOK.image = NSImage.isolated
            imageViewPhpVersionOK.toolTip = "domain_list.tooltips.isolated".localized(site.servingPhpVersion)
        } else {
            imageViewPhpVersionOK.isHidden = (site.preferredPhpVersion == "???"
                                              || !site.isCompatibleWithPreferredPhpVersion)
            imageViewPhpVersionOK.image = NSImage.checkmark
            imageViewPhpVersionOK.toolTip = "domain_list.tooltips.checkmark".localized(site.preferredPhpVersion)
        }
    }

    func populateCell(with proxy: ValetProxy) {
        buttonPhpVersion.isHidden = true
        imageViewPhpVersionOK.isHidden = true
        return
    }

    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.site else { return }

        var validPhpSuggestions: [VersionNumber] {
            if site.isolatedPhpVersion != nil {
                return []
            }

            guard let install = container.phpEnvs.phpInstall else {
                return []
            }

            return container.phpEnvs.validVersions(for: site.preferredPhpVersion)
                .filter({ version in
                version.short != install.version.short
            })
        }

        let button = self.buttonPhpVersion!
        let popover = NSPopover()

        let view = VersionPopoverView(
            site: site,
            validPhpVersions: validPhpSuggestions,
            prefersIsolationSuggestions: Valet.enabled(feature: .isolatedSites),
            parent: popover
        )

        let controller = NSHostingController(rootView: view)

        // Force a layout pass to get accurate sizing, this resolves positioning issues
        controller.view.setFrameSize(NSSize(width: 400, height: 1000))
        controller.view.layoutSubtreeIfNeeded()

        let fittingSize = controller.view.fittingSize
        let finalWidth: CGFloat = min(fittingSize.width, 400)
        let finalHeight: CGFloat = min(fittingSize.height, 300)

        controller.view.frame = NSRect(x: 0, y: 0, width: finalWidth, height: finalHeight)

        popover.contentViewController = controller
        popover.behavior = .transient
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

}
