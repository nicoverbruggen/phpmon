//
//  DomainListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit
import SwiftUI

final class DomainListPhpCell: NSTableCellView, DomainListCellProtocol {
    var container: Container {
        return App.shared.container
    }

    var site: ValetSite?

    private(set) var buttonPhpVersion: NSButton!
    private(set) var imageViewPhpVersionOK: NSImageView!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListPhpCell"
    }

    static func makeCell(identifier: String) -> DomainListPhpCell {
        let cell = DomainListPhpCell()
        cell.identifier = NSUserInterfaceItemIdentifier(identifier)
        cell.setupSubviews()
        return cell
    }

    private func setupSubviews() {
        self.wantsLayer = true

        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setButtonType(.momentaryPushIn)
        if #available(macOS 26.0, *) {
            button.bezelStyle = .glass
        } else {
            button.bezelStyle = .rounded
        }
        button.controlSize = .small
        button.title = "PHP X.X"
        button.alignment = .center
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: button.controlSize))
        button.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 8, weight: .semibold))
        button.imagePosition = .imageRight
        button.setContentHuggingPriority(.defaultHigh, for: .vertical)
        button.target = self
        button.action = #selector(pressedPhpVersion(_:))
        self.addSubview(button)
        self.buttonPhpVersion = button

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(named: "Checkmark")
        imageView.contentTintColor = NSColor(named: "IconColorGreen")
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignLeft
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .vertical)
        self.addSubview(imageView)
        self.imageViewPhpVersionOK = imageView

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            button.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8)
        ])
    }

    func populateCell(with site: ValetSite) {
        self.site = site

        buttonPhpVersion.isHidden = false
        imageViewPhpVersionOK.isHidden = false

        buttonPhpVersion.title = "PHP \(site.servingPhpVersion)"
        buttonPhpVersion.setAccessibilityLabel(buttonPhpVersion.title)

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

    @objc func pressedPhpVersion(_ sender: Any) {
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
                version.short != install.version?.short
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
        let finalHeight: CGFloat = min(fittingSize.height, 700)

        controller.view.frame = NSRect(x: 0, y: 0, width: finalWidth, height: finalHeight)

        popover.contentViewController = controller
        popover.behavior = .transient
        popover.animates = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

}
