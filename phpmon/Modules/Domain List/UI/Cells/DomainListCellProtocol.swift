//
//  DomainListCellProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

protocol DomainListCellProtocol {
    static func getCellIdentifier(for domain: ValetListable) -> String
    func populateCell(with site: ValetSite)
    func populateCell(with proxy: ValetProxy)
}
