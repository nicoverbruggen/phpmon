//
//  DomainListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

final class DomainListPhpCell: NSTableCellView, DomainListCellProtocol {
    var site: ValetSite?

    private(set) var buttonPhpVersion: NSButton!
    private(set) var imageViewIsolation: NSImageView!

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
        button.imagePosition = .imageRight
        button.setContentHuggingPriority(.defaultHigh, for: .vertical)
        button.target = self
        button.action = #selector(pressedPhpVersion(_:))
        self.addSubview(button)
        self.buttonPhpVersion = button

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage.isolated
        imageView.contentTintColor = .secondaryLabelColor
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .vertical)
        self.addSubview(imageView)
        self.imageViewIsolation = imageView

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
        imageViewIsolation.isHidden = false

        buttonPhpVersion.title = "PHP \(site.servingPhpVersion)"
        buttonPhpVersion.setAccessibilityLabel(buttonPhpVersion.title)
        let canIsolate = site.container.valet.features.contains(.isolatedSites)
            && (!site.container.phpEnvs.availablePhpVersions.isEmpty || site.isolatedPhpVersion != nil)
        buttonPhpVersion.isEnabled = canIsolate
        buttonPhpVersion.image = canIsolate
            ? NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 8, weight: .semibold))
            : nil
        buttonPhpVersion.toolTip = (canIsolate ? "domain_list.site_isolation" : "domain_list.isolation_unavailable").localized

        let isIsolated = site.isolatedPhpVersion != nil
        imageViewIsolation.image = isIsolated
            ? NSImage.isolated
            : NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        imageViewIsolation.toolTip = isIsolated
            ? "domain_list.tooltips.isolated".localized(site.servingPhpVersion)
            : "domain_list.sidebar.global".localized
        imageViewIsolation.setAccessibilityLabel(imageViewIsolation.toolTip)
    }

    func populateCell(with proxy: ValetProxy) {
        site = nil
        buttonPhpVersion.isHidden = true
        imageViewIsolation.isHidden = true
        return
    }

    @objc func pressedPhpVersion(_ sender: Any) {
        guard let site,
              buttonPhpVersion.isEnabled,
              !site.container.phpEnvs.isBusy,
              !site.container.valet.isBusy,
              let controller = (window?.windowController as? DomainListWC)?.contentVC,
              !controller.sidebarModel.isBusy else { return }

        let menu = controller.isolationMenu(for: site)
        guard !menu.items.isEmpty else { return }
        let bottom = buttonPhpVersion.isFlipped
            ? buttonPhpVersion.bounds.maxY + 4
            : buttonPhpVersion.bounds.minY - 4
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bottom), in: buttonPhpVersion)
    }
}
