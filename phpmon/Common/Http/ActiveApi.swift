//
//  ActiveApi.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

var Api: ApiProtocol {
    return ActiveApi.shared
}

class ActiveApi {
    static var shared: ApiProtocol = RealApi()

    public static func useTestable(_ responses: [URL: FakeApiResponse]) {
        Self.shared = TestableApi(responses: responses)
    }

    public static func useReal() {
        Self.shared = RealApi()
    }
}
