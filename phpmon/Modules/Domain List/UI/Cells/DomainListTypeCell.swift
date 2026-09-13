//
//  DomainListTypeCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit
import SwiftUI

final class DomainListTypeCell: NSTableCellView, DomainListCellProtocol {
    private var site: ValetSite?
    private(set) var buttonPhpInfo: NSButton!
    private(set) var labelDriver: NSTextField!
    private(set) var labelPhpVersion: NSTextField!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListTypeCell"
    }

    static func makeCell(identifier: String) -> DomainListTypeCell {
        let cell = DomainListTypeCell()
        cell.identifier = NSUserInterfaceItemIdentifier(identifier)
        cell.setupSubviews()
        return cell
    }

    private func setupSubviews() {
        self.wantsLayer = true

        let driver = Self.makeLabel(
            font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            textColor: .labelColor
        )
        let phpVersion = Self.makeLabel(
            font: NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini)),
            textColor: .secondaryLabelColor
        )

        self.addSubview(driver)
        self.addSubview(phpVersion)
        self.labelDriver = driver
        self.labelPhpVersion = phpVersion

        let info = NSButton(image: NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)!,
                            target: self, action: #selector(showPhpDetails(_:)))
        info.translatesAutoresizingMaskIntoConstraints = false
        if #available(macOS 26.0, *) {
            info.bezelStyle = .glass
        } else {
            info.bezelStyle = .circular
        }
        info.imagePosition = .imageOnly
        self.addSubview(info)
        self.buttonPhpInfo = info

        NSLayoutConstraint.activate([
            driver.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            driver.trailingAnchor.constraint(equalTo: info.leadingAnchor, constant: -8),
            driver.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -6),
            phpVersion.topAnchor.constraint(equalTo: driver.bottomAnchor),
            phpVersion.leadingAnchor.constraint(equalTo: driver.leadingAnchor),
            phpVersion.trailingAnchor.constraint(equalTo: driver.trailingAnchor),
            info.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            info.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            info.widthAnchor.constraint(equalToConstant: 28),
            info.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private static func makeLabel(font: NSFont, textColor: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = textColor
        label.alignment = .left
        label.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }

    func populateCell(with site: ValetSite) {
        self.site = site
        self.stylePhpInfoButton(for: site)

        labelDriver.stringValue = site.driver ?? "driver.not_detected".localized

        // Determine the Laravel version
        if site.driver == "Laravel" && site.notableComposerDependencies.keys.contains("laravel/framework") {
            let constraint = site.notableComposerDependencies["laravel/framework"]!
            labelDriver.stringValue = "Laravel (\(constraint))"
        }

        // PHP version
        labelPhpVersion.stringValue = site.preferredPhpVersion == "???" ? "PHP" : "PHP \(site.preferredPhpVersion)"
    }

    func populateCell(with proxy: ValetProxy) {
        site = nil
        buttonPhpInfo.isHidden = true
        labelDriver.stringValue = "Proxy"
        labelPhpVersion.stringValue = "Active"
        return
    }

    private func stylePhpInfoButton(for site: ValetSite) {
        let symbol: String
        let color: NSColor
        let description: String

        if site.preferredPhpVersionSource == .unknown
            || site.preferredPhpVersion == "???"
            || site.servingPhpVersion == "???" {
            symbol = "info.circle"
            color = .labelColor
            description = "alert.unable_to_determine_is_fine".localized
        } else if site.isCompatibleWithPreferredPhpVersion {
            symbol = "checkmark"
            color = NSColor(named: "IconColorGreen") ?? .systemGreen
            description = "alert.php_version_ideal".localized
        } else {
            symbol = "xmark"
            color = NSColor(named: "IconColorRed") ?? .systemRed
            description = "alert.php_version_incorrect".localized
        }

        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        buttonPhpInfo.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        buttonPhpInfo.isHidden = false

        let details: String
        if site.preferredPhpVersionSource == .unknown {
            details = "alert.composer_php_requirement.unable_to_determine".localized
        } else {
            details = "alert.composer_php_requirement.title".localized("\(site.name).\(site.tld)", site.preferredPhpVersion)
        }
        buttonPhpInfo.toolTip = "\(description) \(details)"
        buttonPhpInfo.setAccessibilityLabel(buttonPhpInfo.toolTip)
    }

    @objc func showPhpDetails(_ sender: Any) {
        guard let site else { return }
        let container = site.container

        var validPhpSuggestions: [VersionNumber] {
            if site.isolatedVersion != nil {
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

        let button = self.buttonPhpInfo!
        let popover = NSPopover()

        let view = VersionPopoverView(
            site: site,
            validPhpVersions: validPhpSuggestions,
            prefersIsolationSuggestions: container.valet.features.contains(.isolatedSites),
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
