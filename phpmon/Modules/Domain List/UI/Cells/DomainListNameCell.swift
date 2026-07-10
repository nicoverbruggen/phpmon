//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

final class DomainListNameCell: NSTableCellView, DomainListCellProtocol {
    private(set) var labelSiteName: NSTextField!
    private(set) var labelPathName: NSTextField!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return domain.getListableFavorited() ? "domainListNameCellFavorited" : "domainListNameCell"
    }

    static func makeCell(identifier: String) -> DomainListNameCell {
        let cell = DomainListNameCell()
        cell.identifier = NSUserInterfaceItemIdentifier(identifier)
        cell.setupSubviews(favorited: identifier == "domainListNameCellFavorited")
        return cell
    }

    private func setupSubviews(favorited: Bool) {
        self.wantsLayer = true

        let siteName = Self.makeLabel(
            text: "my-domain-name.test",
            font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            textColor: .controlTextColor
        )
        let pathName = Self.makeLabel(
            text: "~/path/to/site",
            font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            textColor: .secondaryLabelColor
        )

        self.addSubview(siteName)
        self.addSubview(pathName)
        self.labelSiteName = siteName
        self.labelPathName = pathName

        var constraints: [NSLayoutConstraint] = [
            siteName.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: favorited ? 35 : 5
            ),
            siteName.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            pathName.topAnchor.constraint(equalTo: siteName.bottomAnchor),
            pathName.leadingAnchor.constraint(equalTo: siteName.leadingAnchor),
            self.trailingAnchor.constraint(greaterThanOrEqualTo: siteName.trailingAnchor, constant: 20),
            self.trailingAnchor.constraint(greaterThanOrEqualTo: pathName.trailingAnchor, constant: 20)
        ]

        if favorited {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = NSImage(systemSymbolName: "star.circle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(scale: .large))
            imageView.contentTintColor = NSColor(named: "AccentColor")
            imageView.imageScaling = .scaleProportionallyDown
            imageView.imageAlignment = .alignLeft
            imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
            imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .vertical)
            self.addSubview(imageView)

            constraints += [
                imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
                imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
                self.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 9)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    private static func makeLabel(text: String, font: NSFont, textColor: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = textColor
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        return label
    }

    func populateCell(with site: ValetSite) {
        labelSiteName.stringValue = "\(site.name).\(site.tld)"
        labelPathName.stringValue = site.absolutePathRelative
    }

    func populateCell(with proxy: ValetProxy) {
        labelSiteName.stringValue = "\(proxy.domain).\(proxy.tld)"
        labelPathName.stringValue = proxy.target
    }
}
