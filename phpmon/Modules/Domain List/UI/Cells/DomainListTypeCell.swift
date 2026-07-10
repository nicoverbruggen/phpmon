//
//  DomainListTypeCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

final class DomainListTypeCell: NSTableCellView, DomainListCellProtocol {
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

        NSLayoutConstraint.activate([
            driver.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            self.trailingAnchor.constraint(equalTo: driver.trailingAnchor),
            driver.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -6),
            phpVersion.topAnchor.constraint(equalTo: driver.bottomAnchor),
            phpVersion.leadingAnchor.constraint(equalTo: driver.leadingAnchor),
            phpVersion.trailingAnchor.constraint(equalTo: driver.trailingAnchor)
        ])
    }

    func populateCell(with site: ValetSite) {
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
        labelDriver.stringValue = "Proxy"
        labelPhpVersion.stringValue = "Active"
        return
    }
}
