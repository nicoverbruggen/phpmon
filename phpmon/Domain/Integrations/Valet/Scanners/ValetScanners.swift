//
//  Valet+Scanners.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetScanner {

    static var active: DomainScanner {
        get { Valet.shared.scanner }
        set { Valet.shared.scanner = newValue }
    }

    public static func useFake() {
        ValetScanner.active = FakeDomainScanner()
    }

}
