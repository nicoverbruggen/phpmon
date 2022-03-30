//
//  DomainListNameCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListProxiesCell: NSTableCellView, DomainListCellProtocol
{
    static let reusableName = "domainListProxiesCell"
    
    @IBOutlet weak var textFieldPrimary: NSTextField!
    @IBOutlet weak var textFieldAdditional: NSTextField!
    @IBOutlet weak var buttonProxyList: NSButton!
    
    func populateCell(with site: ValetSite) {
        // Show the first proxy
        textFieldPrimary.stringValue = (site.proxies.count == 0)
            ? ""
            : site.proxies[0]
        
        // Show additional proxy count
        textFieldAdditional.stringValue = site.proxies.count > 1
            ? "and \(site.proxies.count - 1) more active"
            : site.proxies.count == 1 ? "(active)" : ""
        
        // Show button
        buttonProxyList.isHidden = site.proxies.count == 0
    }
}
