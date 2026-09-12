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

        let driver = NSTextField(labelWithString: "Laravel")
        driver.translatesAutoresizingMaskIntoConstraints = false
        driver.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        driver.textColor = .labelColor
        driver.alignment = .left
        driver.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        driver.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.addSubview(driver)
        self.labelDriver = driver

        let phpVersion = NSTextField(labelWithString: "PHP 8.0")
        phpVersion.translatesAutoresizingMaskIntoConstraints = false
        phpVersion.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini))
        phpVersion.textColor = .secondaryLabelColor
        phpVersion.alignment = .left
        phpVersion.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        phpVersion.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.addSubview(phpVersion)
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

    func populateCell(with site: ValetSite) {
        self.site = site
        buttonPhpInfo.isHidden = false
        let details = site.preferredPhpVersionSource == .unknown
            ? "alert.composer_php_requirement.unable_to_determine".localized
            : "alert.composer_php_requirement.title".localized("\(site.name).\(site.tld)", site.preferredPhpVersion)
        let status: (symbol: String, color: NSColor, description: String)
        if site.preferredPhpVersionSource == .unknown || site.preferredPhpVersion == "???" || site.servingPhpVersion == "???" {
            status = ("info.circle", .labelColor, "alert.unable_to_determine_is_fine".localized)
        } else if site.isCompatibleWithPreferredPhpVersion {
            status = ("checkmark", NSColor(named: "IconColorGreen") ?? .systemGreen, "alert.php_version_ideal".localized)
        } else {
            status = ("xmark", NSColor(named: "IconColorRed") ?? .systemRed, "alert.php_version_incorrect".localized)
        }
        buttonPhpInfo.image = NSImage(systemSymbolName: status.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [status.color])))
        buttonPhpInfo.toolTip = "\(status.description) \(details)"
        buttonPhpInfo.setAccessibilityLabel(buttonPhpInfo.toolTip)
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

    @objc func showPhpDetails(_ sender: Any) {
        guard let site else { return }
        let container = site.container

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
