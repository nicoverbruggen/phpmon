//
//  SiteListCellProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

protocol SiteListCellProtocol {
    func populateCell(with site: ValetSite)
}
