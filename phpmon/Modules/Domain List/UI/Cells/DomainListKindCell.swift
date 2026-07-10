//
//  DomainListKindCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

final class DomainListKindCell: NSTableCellView, DomainListCellProtocol {
    private(set) var imageViewType: NSImageView!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListKindCell"
    }

    static func makeCell(identifier: String) -> DomainListKindCell {
        let cell = DomainListKindCell()
        cell.identifier = NSUserInterfaceItemIdentifier(identifier)
        cell.setupSubviews()
        return cell
    }

    private func setupSubviews() {
        self.wantsLayer = true

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(named: "IconLinked")
        imageView.contentTintColor = .tertiaryLabelColor
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignLeft
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .vertical)
        self.addSubview(imageView)
        self.imageViewType = imageView

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

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
