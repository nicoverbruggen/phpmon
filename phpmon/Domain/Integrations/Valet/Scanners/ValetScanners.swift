//
//  Valet+Scanners.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetScanner {

    static var active: DomainScanner = ValetDomainScanner(App.shared.container)

    public static func useFake() {
        ValetScanner.active = FakeDomainScanner()
    }

}
