//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListNameCell: NSTableCellView, DomainListCellProtocol {
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!

    static func getCellIdentifier(for domain: ValetListable) -> String {
        return domain.getListableFavorited() ? "domainListNameCellFavorited" : "domainListNameCell"
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
