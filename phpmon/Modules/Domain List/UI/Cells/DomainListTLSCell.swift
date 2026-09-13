//
//  DomainListTLSCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit
import SwiftUI

final class DomainListTLSCell: NSTableCellView, DomainListCellProtocol {
    var domain: ValetListable?

    private(set) var buttonLockStatus: NSButton!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return "domainListTLSCell"
    }

    static func makeCell(identifier: String) -> DomainListTLSCell {
        let cell = DomainListTLSCell()
        cell.identifier = NSUserInterfaceItemIdentifier(identifier)
        cell.setupSubviews()
        return cell
    }

    private func setupSubviews() {
        // The initial frame matters: `styleLockButton` computes its circular
        // corner radius from `bounds`, which would be zero before the first
        // layout pass otherwise (the storyboard prototype came pre-sized).
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 28, height: 28))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setButtonType(.momentaryPushIn)
        if #available(macOS 26.0, *) {
            button.bezelStyle = .glass
        } else {
            button.bezelStyle = .regularSquare
            button.isBordered = false
        }
        button.title = ""
        button.alignment = .center
        button.lineBreakMode = .byTruncatingTail
        button.image = NSImage(named: "Lock")
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.state = .on
        button.target = self
        button.action = #selector(pressedPhpVersion(_:))
        self.addSubview(button)
        self.buttonLockStatus = button

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    func styleLockButton(secured: Bool, color: NSColor) {
        let image = NSImage(named: secured ? "Lock" : "LockUnlocked")!
            .resized(to: NSSize(width: 20, height: 20))
        if #available(macOS 26.0, *) {
            // Bordered buttons do not apply contentTintColor to their images.
            buttonLockStatus.image = NSImage(size: image.size, flipped: false) { rect in
                image.draw(in: rect)
                color.setFill()
                rect.fill(using: .sourceAtop)
                return true
            }
        } else {
            buttonLockStatus.image = image
            buttonLockStatus.contentTintColor = color
            buttonLockStatus.wantsLayer = true
            buttonLockStatus.layer?.backgroundColor = color.withAlphaComponent(0.10).cgColor
            buttonLockStatus.layer?.cornerRadius = buttonLockStatus.bounds.width / 2
            buttonLockStatus.layer?.masksToBounds = true
        }
    }

    func populateCell(with site: ValetSite) {
        domain = site

        let color = {
            if site.secured && site.isCertificateExpired {
                return NSColor.statusColorOrange
            }

            return site.secured ? NSColor.statusColorNeutral : NSColor.statusColorRed
        }()

        self.styleLockButton(
            secured: site.secured,
            color: color
        )
    }

    func populateCell(with proxy: ValetProxy) {
        domain = proxy

        let color = {
            if proxy.secured && proxy.isCertificateExpired {
                return NSColor.statusColorOrange
            }

            return proxy.secured ? NSColor.statusColorNeutral : NSColor.statusColorRed
        }()

        self.styleLockButton(
            secured: proxy.secured,
            color: color
        )
    }

    var container: Container {
        return App.shared.container
    }

    @objc func pressedPhpVersion(_ sender: Any) {
        guard let site = self.domain else { return }

        let button = self.buttonLockStatus!
        let popover = NSPopover()

        let view = SecurePopoverView(
            name: site.getListableName(),
            tld: Valet.shared.config.tld,
            expires: site.getListableCertificateExpiryDate(),
            callback: {
                WindowManager.controller(of: DomainListWC.self)?.contentVC
                    .checkForCertificateRenewal()
            }
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
