//
//  FakeValetProxy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/12/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeValetProxy: ValetProxy {
    convenience init(
        withDomain domain: String,
        target: String,
        secure: Bool,
        tld: String
    ) {
        self.init(
            App.shared.container,
            domain: domain,
            target: target,
            secure: secure,
            tld: tld
        )
    }

    override func determineSecured() {
        return
    }
}
