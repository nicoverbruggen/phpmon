//
//  DomainListCellProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

protocol DomainListCellProtocol: NSTableCellView {
    static func getCellIdentifier(for domain: ValetListable) -> String
    static func makeCell(identifier: String) -> Self
    func populateCell(with site: ValetSite)
    func populateCell(with proxy: ValetProxy)
}
