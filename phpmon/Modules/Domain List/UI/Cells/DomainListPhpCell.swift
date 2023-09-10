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
    static let reusableName = "domainListPhpCell"

    var site: ValetSite?

    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!

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
            imageViewPhpVersionOK.image = NSImage(named: "Isolated")
            imageViewPhpVersionOK.toolTip = "domain_list.tooltips.isolated".localized(site.servingPhpVersion)
        } else {
            imageViewPhpVersionOK.isHidden = (site.preferredPhpVersion == "???"
                                              || !site.isCompatibleWithPreferredPhpVersion)
            imageViewPhpVersionOK.image = NSImage(named: "Checkmark")
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

            guard let install = PhpEnvironments.phpInstall else {
                return []
            }

            return PhpEnvironments.shared.validVersions(for: site.preferredPhpVersion).filter({ version in
                version.short != install.version.short
            })
        }

        let button = self.buttonPhpVersion!
        let popover = NSPopover()

        let view = VersionPopoverView(site: site, validPhpVersions: validPhpSuggestions, parent: popover)

        popover.contentViewController = NSHostingController(rootView: view)
        popover.behavior = .transient
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

}
