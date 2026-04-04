//
//  PhpSwitcherDelegate.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol PhpSwitcherDelegate: AnyObject {

    func switcherDidCompleteSwitch(to version: String)

}
