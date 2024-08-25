//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListNameCell: NSTableCellView, DomainListCellProtocol {
    static let reusableName = "domainListNameCell"

    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!

    func populateCell(with site: ValetSite) {
        let favoritePrefix = site.favorited ? "★ " : ""
        labelSiteName.stringValue = "\(favoritePrefix)\(site.name).\(site.tld)"
        labelPathName.stringValue = site.absolutePathRelative
    }

    func populateCell(with proxy: ValetProxy) {
        let favoritePrefix = proxy.favorited ? "★ " : ""
        labelSiteName.stringValue = "\(favoritePrefix)\(proxy.domain).\(proxy.tld)"
        labelPathName.stringValue = proxy.target
    }
}
