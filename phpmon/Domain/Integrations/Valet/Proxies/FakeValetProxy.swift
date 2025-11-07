//
//  FakeValetProxy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/12/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeValetProxy: ValetProxy {
    convenience init(
        fakeDomain: String,
        target: String,
        secure: Bool,
        tld: String
    ) {
        self.init(
            App.shared.container,
            domain: fakeDomain,
            target: tld,
            secure: secure,
            tld: tld
        )
    }

    override func determineSecured() {
        return
    }
}
